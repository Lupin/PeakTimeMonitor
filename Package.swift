// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PeakTimeMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PeakTimeMonitor",
            targets: ["PeakTimeMonitor"]
        )
    ],
    targets: [
        .target(
            name: "PeakTimeMonitorLib",
            path: "Sources/PeakTimeMonitorLib"
        ),
        .executableTarget(
            name: "PeakTimeMonitor",
            dependencies: ["PeakTimeMonitorLib"],
            path: "Sources/PeakTimeMonitor"
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["PeakTimeMonitorLib"],
            path: "Tests/TestRunner"
        ),
        .target(
            name: "PeakTimeWidget",
            dependencies: ["PeakTimeMonitorLib"],
            path: "PeakTimeWidget",
            exclude: ["Info.plist"],
            swiftSettings: [
                .unsafeFlags(["-application-extension"])
            ]
        )
    ]
)
