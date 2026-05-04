// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_battery",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "flutter-battery", targets: ["flutter_battery"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_battery",
            dependencies: [],
            path: "Sources"
        )
    ]
)
