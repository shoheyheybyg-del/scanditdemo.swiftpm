import SwiftUI
import AVFoundation
import Vision

struct ScanResult {
    let barcode: String
    let recognizedTexts: [String]
}

struct ScannerView: View {
    let scanMode: ScanMode
    let textRecognitionEnabled: Bool
    @Binding var scannedResults: [ScanResult]
    @Binding var isPresented: Bool

    @State private var lastScannedCode: String?
    @State private var scanCount: Int = 0
    @State private var isProcessingText = false

    var body: some View {
        ZStack {
            ScannerRepresentable(
                scanMode: scanMode,
                textRecognitionEnabled: textRecognitionEnabled,
                onScanCompleted: handleScanResult
            )

            VStack {
                // Top bar with info and close button
                HStack {
                    VStack(alignment: .leading) {
                        Text(scanMode.rawValue + "スキャン")
                            .font(.headline)
                            .foregroundColor(.white)
                        if textRecognitionEnabled {
                            Text("テキスト認識: ON")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
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

                // Processing indicator
                if isProcessingText {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("テキスト認識中...")
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                }

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

    private func handleScanResult(_ result: ScanResult) {
        // Avoid duplicate consecutive scans
        if result.barcode == lastScannedCode && scanMode == .multiple {
            return
        }

        lastScannedCode = result.barcode
        scannedResults.append(result)
        scanCount += 1

        if scanMode == .single {
            isPresented = false
        }
    }
}

struct ScannerRepresentable: UIViewControllerRepresentable {
    let scanMode: ScanMode
    let textRecognitionEnabled: Bool
    let onScanCompleted: (ScanResult) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.scanMode = scanMode
        controller.textRecognitionEnabled = textRecognitionEnabled
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let onScanCompleted: (ScanResult) -> Void

        init(onScanCompleted: @escaping (ScanResult) -> Void) {
            self.onScanCompleted = onScanCompleted
        }

        func didCompleteScan(_ result: ScanResult) {
            onScanCompleted(result)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didCompleteScan(_ result: ScanResult)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    var scanMode: ScanMode = .single
    var textRecognitionEnabled: Bool = false

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedCode: String?
    private var lastScanTime: Date?
    private var isProcessingBarcode = false
    private var pendingBarcode: String?
    private var recognizedTexts: [String] = []
    private var textRecognitionRequest: VNRecognizeTextRequest?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupTextRecognition()
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

    private func setupTextRecognition() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            var texts: [String] = []
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    texts.append(topCandidate.string)
                }
            }

            DispatchQueue.main.async {
                self?.recognizedTexts = texts
                self?.completeBarcodeScan()
            }
        }
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.recognitionLanguages = ["ja-JP", "en-US"]
        textRecognitionRequest?.usesLanguageCorrection = true
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

        // Barcode metadata output
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

        // Video data output for text recognition
        if textRecognitionEnabled {
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
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

        // Prevent processing while already handling a barcode
        guard !isProcessingBarcode else { return }

        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        if textRecognitionEnabled {
            // Store barcode and wait for text recognition
            isProcessingBarcode = true
            pendingBarcode = stringValue
            // Text recognition will happen in captureOutput and call completeBarcodeScan
        } else {
            // No text recognition, complete immediately
            let result = ScanResult(barcode: stringValue, recognizedTexts: [])
            delegate?.didCompleteScan(result)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard textRecognitionEnabled,
              isProcessingBarcode,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = textRecognitionRequest else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func completeBarcodeScan() {
        guard let barcode = pendingBarcode else { return }

        let result = ScanResult(barcode: barcode, recognizedTexts: recognizedTexts)
        delegate?.didCompleteScan(result)

        // Reset state
        pendingBarcode = nil
        recognizedTexts = []
        isProcessingBarcode = false
    }
}
