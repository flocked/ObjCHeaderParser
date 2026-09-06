import Foundation
import CClang

public final class ClangIndex: @unchecked Sendable {
    package let rawValue: CXIndex

    public init(
        excludeDeclarationsFromPCH: Bool = false,
        displayDiagnostics: Bool = false
    ) {
        rawValue = clang_createIndex(
            excludeDeclarationsFromPCH ? 1 : 0,
            displayDiagnostics ? 1 : 0
        )
    }

    deinit {
        clang_disposeIndex(rawValue)
    }

    public func parse(
        file url: URL,
        arguments: [String] = [],
        options: TranslationUnit.ParseOptions = []
    ) throws -> TranslationUnit {
        try TranslationUnit(
            index: self,
            file: url,
            arguments: arguments,
            options: options
        )
    }
}
