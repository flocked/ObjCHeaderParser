import Foundation
import ObjCParser

let arguments = CommandLine.arguments

guard arguments.count >= 2 else {
    fputs("Usage: objc-parser-demo <header> [sdk-path]\n", stderr)
    exit(2)
}

let headerURL = URL(fileURLWithPath: arguments[1])
let sdkURL = arguments.count >= 3 ? URL(fileURLWithPath: arguments[2]) : nil
let parser = ObjCParser(configuration: .init(sdk: sdkURL))

let result = try parser.parseResult(headerURL)

for diagnostic in result.diagnostics where diagnostic.severity != .ignored {
    fputs("\(diagnostic.formatted)\n", stderr)
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let data = try encoder.encode(result.header)
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data("\n".utf8))
