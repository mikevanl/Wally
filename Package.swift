// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Wally",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Wally",
            path: "Sources/Wally",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .executableTarget(
            name: "wallpaper",
            path: "Sources/wallpaper"
        ),
    ]
)
