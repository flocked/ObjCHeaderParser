import Foundation
import CClang

public final class TranslationUnit: @unchecked Sendable {
    public struct ParseOptions: OptionSet, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let detailedPreprocessingRecord = Self(rawValue: 0x01)
        public static let incomplete = Self(rawValue: 0x02)
        public static let precompiledPreamble = Self(rawValue: 0x04)
        public static let cacheCompletionResults = Self(rawValue: 0x08)
        public static let skipFunctionBodies = Self(rawValue: 0x40)
        public static let keepGoing = Self(rawValue: 0x200)
        public static let includeAttributedTypes = Self(rawValue: 0x1000)
        public static let visitImplicitAttributes = Self(rawValue: 0x2000)
    }

    package let rawValue: CXTranslationUnit

    package init(
        index: ClangIndex,
        file url: URL,
        arguments: [String],
        options: ParseOptions
    ) throws {
        var unit: CXTranslationUnit?

        let result: Int32 = try arguments.withUnsafeCStrings { argumentPointers in
            try url.path.withCString { sourceFilename in
                CClang_parseTranslationUnit2(
                    index.rawValue,
                    sourceFilename,
                    argumentPointers.baseAddress,
                    Int32(argumentPointers.count),
                    nil,
                    0,
                    options.rawValue,
                    &unit
                )
            }
        }

        guard result == 0, let unit else {
            throw ClangError.parseFailed(code: result)
        }

        rawValue = unit
    }

    deinit {
        clang_disposeTranslationUnit(rawValue)
    }

    public var cursor: Cursor {
        Cursor(rawValue: clang_getTranslationUnitCursor(rawValue), owner: self)
    }

    public var diagnostics: [Diagnostic] {
        let count = clang_getNumDiagnostics(rawValue)
        return (0..<count).compactMap { index in
            guard let value = clang_getDiagnostic(rawValue, index) else { return nil }
            return Diagnostic(rawValue: value)
        }
    }
}

private extension Array where Element == String {
    func withUnsafeCStrings<R>(
        _ body: (UnsafeBufferPointer<UnsafePointer<CChar>?>) throws -> R
    ) rethrows -> R {
        func recurse(
            _ index: Int,
            _ pointers: inout [UnsafePointer<CChar>?]
        ) throws -> R {
            if index == count {
                return try pointers.withUnsafeBufferPointer(body)
            }

            return try self[index].withCString { pointer in
                pointers.append(pointer)
                defer { pointers.removeLast() }
                return try recurse(index + 1, &pointers)
            }
        }

        var pointers: [UnsafePointer<CChar>?] = []
        pointers.reserveCapacity(count)
        return try recurse(0, &pointers)
    }
}
