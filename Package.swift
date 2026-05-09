// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "PortManager",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "PortManager", targets: ["PortManager"])
    ],
    targets: [
        .executableTarget(
            name: "PortManager",
            path: "PortManager",
            exclude: ["Info.plist"],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
