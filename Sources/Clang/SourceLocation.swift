import Foundation
import CClang

public struct SourceLocation: Hashable, Sendable {
    public enum Resolution: Hashable, Sendable { case spelling, expansion, file }

    public let file: URL?
    public let line: UInt32
    public let column: UInt32
    public let offset: UInt32

    package init(_ rawValue: CXSourceLocation, resolution: Resolution = .spelling) {
        var file: CXFile?
        var line: UInt32 = 0
        var column: UInt32 = 0
        var offset: UInt32 = 0

        switch resolution {
        case .spelling:
            clang_getSpellingLocation(rawValue, &file, &line, &column, &offset)
        case .expansion:
            clang_getExpansionLocation(rawValue, &file, &line, &column, &offset)
        case .file:
            clang_getFileLocation(rawValue, &file, &line, &column, &offset)
        }

        let fileURL: URL?
        if let file {
            let path = clang_getFileName(file).takeString()
            fileURL = path.isEmpty ? nil : URL(fileURLWithPath: path)
        } else {
            fileURL = nil
        }

        self.file = fileURL
        self.line = line
        self.column = column
        self.offset = offset
    }
}
