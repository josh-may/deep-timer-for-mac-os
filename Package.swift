// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DeepTimer",
            targets: ["DeepTimer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DeepTimer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
