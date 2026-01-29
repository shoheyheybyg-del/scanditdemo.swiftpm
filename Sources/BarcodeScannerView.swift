import SwiftUI
import ScanditBarcodeCapture

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onScanComplete: (ScanResult) -> Void

    @StateObject private var viewModel = BarcodeScannerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                DataCaptureViewRepresentable(dataCaptureContext: viewModel.dataCaptureContext)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    if let lastScanned = viewModel.lastScannedBarcode {
                        scannedInfoCard(lastScanned)
                    }
                }
            }
            .navigationTitle("スキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.stopScanning()
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
            .onChange(of: viewModel.lastScannedBarcode) { _, newValue in
                if let result = newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onScanComplete(result)
                    }
                }
            }
        }
    }

    private func scannedInfoCard(_ result: ScanResult) -> some View {
        VStack(spacing: 8) {
            Text("スキャン完了")
                .font(.headline)
                .foregroundColor(.green)

            Text(result.barcodeData)
                .font(.body)
                .lineLimit(2)

            Text(result.symbologyName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - ViewModel
@MainActor
class BarcodeScannerViewModel: NSObject, ObservableObject {
    // TODO: Scanditのライセンスキーをここに入力してください
    // https://ssl.scandit.com/ で無料トライアルキーを取得できます
    private static let licenseKey = "YOUR_SCANDIT_LICENSE_KEY"

    @Published var lastScannedBarcode: ScanResult?

    let dataCaptureContext: DataCaptureContext
    private var camera: Camera?
    private var barcodeCapture: BarcodeCapture?

    override init() {
        // DataCaptureContextの初期化
        dataCaptureContext = DataCaptureContext(licenseKey: Self.licenseKey)

        super.init()

        setupCamera()
        setupBarcodeCapture()
    }

    private func setupCamera() {
        camera = Camera.default
        dataCaptureContext.setFrameSource(camera, completionHandler: nil)

        let cameraSettings = BarcodeCapture.recommendedCameraSettings
        camera?.apply(cameraSettings, completionHandler: nil)
    }

    private func setupBarcodeCapture() {
        let settings = BarcodeCaptureSettings()

        // 対応するバーコードの種類を設定
        settings.set(symbology: .ean13UPCA, enabled: true)
        settings.set(symbology: .ean8, enabled: true)
        settings.set(symbology: .upce, enabled: true)
        settings.set(symbology: .code128, enabled: true)
        settings.set(symbology: .code39, enabled: true)
        settings.set(symbology: .code93, enabled: true)
        settings.set(symbology: .interleaved2Of5, enabled: true)
        settings.set(symbology: .qr, enabled: true)
        settings.set(symbology: .dataMatrix, enabled: true)
        settings.set(symbology: .aztec, enabled: true)
        settings.set(symbology: .pdf417, enabled: true)

        barcodeCapture = BarcodeCapture(context: dataCaptureContext, settings: settings)
        barcodeCapture?.addListener(self)
    }

    func startScanning() {
        lastScannedBarcode = nil
        camera?.switch(toDesiredState: .on)
        barcodeCapture?.isEnabled = true
    }

    func stopScanning() {
        barcodeCapture?.isEnabled = false
        camera?.switch(toDesiredState: .off)
    }
}

// MARK: - BarcodeCaptureListener
extension BarcodeScannerViewModel: BarcodeCaptureListener {
    nonisolated func barcodeCapture(
        _ barcodeCapture: BarcodeCapture,
        didScanIn session: BarcodeCaptureSession,
        frameData: FrameData
    ) {
        guard let barcode = session.newlyRecognizedBarcode else { return }

        let data = barcode.data ?? "不明"
        let symbology = barcode.symbology.description

        Task { @MainActor in
            self.lastScannedBarcode = ScanResult(
                barcodeData: data,
                symbologyName: symbology
            )
            self.barcodeCapture?.isEnabled = false
        }
    }
}

// MARK: - DataCaptureView UIKit Wrapper
struct DataCaptureViewRepresentable: UIViewRepresentable {
    let dataCaptureContext: DataCaptureContext

    func makeUIView(context: Context) -> DataCaptureView {
        let view = DataCaptureView(context: dataCaptureContext, frame: .zero)
        return view
    }

    func updateUIView(_ uiView: DataCaptureView, context: Context) {
        // No update needed
    }
}
