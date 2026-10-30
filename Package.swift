// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Apex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Apex",
            targets: ["Apex"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Apex",
            path: "Sources",
            exclude: ["ApexResources"],
            cSettings: [],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("IOKit"),
                .linkedFramework("Vision"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("LocalAuthentication"),
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
