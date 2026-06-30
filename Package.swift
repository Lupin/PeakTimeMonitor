// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PeakTimeMonitor",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PeakTimeMonitor", targets: ["PeakTimeMonitor"])
    ],
    targets: [
        .executableTarget(
            name: "PeakTimeMonitor",
            path: "PeakTimeMonitorApp"
        )
    ]
)
