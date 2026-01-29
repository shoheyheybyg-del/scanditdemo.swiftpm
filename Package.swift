// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScanditDemo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .iOSApplication(
            name: "ScanditDemo",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.scanditdemo",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .barcode),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .camera(purposeString: "カメラを使用してバーコードをスキャンします")
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Scandit/datacapture-spm.git", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "ScanditBarcodeCapture", package: "datacapture-spm")
            ],
            path: "Sources"
        )
    ]
)
