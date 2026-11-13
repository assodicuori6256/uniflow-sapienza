// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UniFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "UniFlow",
            targets: ["UniFlow"]
        )
    ],
    targets: [
        .executableTarget(
            name: "UniFlow",
            path: "Sources/UniFlow"
        )
    ]
)
