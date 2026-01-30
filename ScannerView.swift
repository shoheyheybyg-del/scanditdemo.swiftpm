import SwiftUI
import AVFoundation

struct ScannerView: View {
    let scanMode: ScanMode
    @Binding var scannedCodes: [String]
    @Binding var isPresented: Bool

    @State private var lastScannedCode: String?
    @State private var scanCount: Int = 0

    var body: some View {
        ZStack {
            ScannerRepresentable(
                scanMode: scanMode,
                onCodeScanned: handleScannedCode
            )

            VStack {
                // Top bar with info and close button
                HStack {
                    VStack(alignment: .leading) {
                        Text(scanMode.rawValue + "スキャン")
                            .font(.headline)
                            .foregroundColor(.white)
                        if scanMode == .multiple {
                            Text("スキャン数: \(scanCount)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))

                Spacer()

                // Last scanned code display (for multiple mode)
                if scanMode == .multiple, let lastCode = lastScannedCode {
                    Text("最後にスキャン: \(lastCode)")
                        .font(.caption)
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 8)
                }

                // Done button for multiple mode
                if scanMode == .multiple {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("完了 (\(scanCount)件)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        // Avoid duplicate consecutive scans
        if code == lastScannedCode && scanMode == .multiple {
            return
        }

        lastScannedCode = code
        scannedCodes.append(code)
        scanCount += 1

        if scanMode == .single {
            isPresented = false
        }
    }
}

struct ScannerRepresentable: UIViewControllerRepresentable {
    let scanMode: ScanMode
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.scanMode = scanMode
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func didFindCode(_ code: String) {
            onCodeScanned(code)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    var scanMode: ScanMode = .single

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedCode: String?
    private var lastScanTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showNoCameraAlert()
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showNoCameraAlert()
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            showNoCameraAlert()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .pdf417,
                .qr,
                .code128,
                .code39,
                .code93,
                .upce,
                .aztec,
                .dataMatrix
            ]
        } else {
            showNoCameraAlert()
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        self.previewLayer = previewLayer
        self.captureSession = session
    }

    private func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        captureSession?.stopRunning()
    }

    private func showNoCameraAlert() {
        let alert = UIAlertController(
            title: "カメラエラー",
            message: "カメラにアクセスできません。設定でカメラの使用を許可してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        // For multiple mode, add a small delay between same code scans
        if scanMode == .multiple {
            let now = Date()
            if stringValue == lastScannedCode,
               let lastTime = lastScanTime,
               now.timeIntervalSince(lastTime) < 2.0 {
                return
            }
            lastScannedCode = stringValue
            lastScanTime = now
        }

        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        delegate?.didFindCode(stringValue)
    }
}
