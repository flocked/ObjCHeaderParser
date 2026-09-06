// swift-tools-version: 6.0

import Foundation
import PackageDescription

private func llvmPrefix() -> String {
    let environment = ProcessInfo.processInfo.environment

    if let path = environment["LLVM_PREFIX"], !path.isEmpty {
        return path
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["brew", "--prefix", "llvm"]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        }
    } catch {
        // Fall through to the standard Homebrew locations below.
    }

    #if arch(arm64)
    return "/opt/homebrew/opt/llvm"
    #else
    return "/usr/local/opt/llvm"
    #endif
}

let llvm = llvmPrefix()
let libClangSwiftSettings: [SwiftSetting] = [
    .unsafeFlags([
        "-Xcc", "-I\(llvm)/include"
    ])
]

let package = Package(
    name: "ObjCHeaderParser",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ObjCParser",
            targets: ["ObjCParser"]
        ),
    ],
    targets: [
        .target(
            name: "CClang",
            path: "Sources/CClang",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-I\(llvm)/include"
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-L\(llvm)/lib",
                    "-lclang",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "\(llvm)/lib"
                ])
            ]
        ),
        .target(
            name: "Clang",
            dependencies: ["CClang"],
            swiftSettings: libClangSwiftSettings,
            linkerSettings: [
                .unsafeFlags([
                    "-L\(llvm)/lib",
                    "-lclang",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "\(llvm)/lib"
                ])
            ]
        ),
        .target(
            name: "ObjCParser",
            dependencies: ["Clang", "CClang"],
            swiftSettings: libClangSwiftSettings
        ),
        .executableTarget(
            name: "ObjCParserDemo",
            dependencies: ["ObjCParser"],
            swiftSettings: libClangSwiftSettings
        ),
        .testTarget(
            name: "ObjCParserTests",
            dependencies: ["ObjCParser"],
            swiftSettings: libClangSwiftSettings
        ),
    ]
)
