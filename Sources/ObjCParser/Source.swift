import Foundation
import Clang

public struct ObjCSourceLocation: Codable, Hashable, Sendable {
    public let file: URL?
    public let line: UInt32
    public let column: UInt32
    public let offset: UInt32

    public init(file: URL?, line: UInt32, column: UInt32, offset: UInt32) {
        self.file = file; self.line = line; self.column = column; self.offset = offset
    }

    init(_ location: Clang.SourceLocation) {
        self.init(file: location.file, line: location.line, column: location.column, offset: location.offset)
    }
}

public struct ObjCSourceRange: Codable, Hashable, Sendable {
    public let start: ObjCSourceLocation
    public let end: ObjCSourceLocation

    public init(start: ObjCSourceLocation, end: ObjCSourceLocation) {
        self.start = start; self.end = end
    }

    init(_ range: Clang.SourceRange) {
        self.init(start: ObjCSourceLocation(range.start), end: ObjCSourceLocation(range.end))
    }
}
