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
            path: ".",
            sources: [
                "DeepTimerApp.swift",
                "AppDelegate.swift",
                "TimerManager.swift",
                "AudioPlayer.swift"
            ],
            resources: [
                .process("brown-noise-1-30.mp3"),
                .process("alarm.mp3")
            ]
        )
    ]
)
