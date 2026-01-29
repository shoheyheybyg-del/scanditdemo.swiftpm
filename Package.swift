// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "scanditdemo",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "scanditdemo",
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
                .portraitUpsideDown
            ],
            capabilities: [
                .camera(purposeString: "バーコードをスキャンするためにカメラを使用します")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
