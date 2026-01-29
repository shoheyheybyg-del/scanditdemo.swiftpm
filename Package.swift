// swift-tools-version: 5.8

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
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
