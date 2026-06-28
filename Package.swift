// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlassTime",
    platforms: [
        .macOS("26.0")
    ],
    targets: [
        .executableTarget(
            name: "GlassTime",
            path: "Sources/GlassTime"
        )
    ]
)
