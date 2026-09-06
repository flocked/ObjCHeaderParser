import CClang

public struct SourceRange: @unchecked Sendable {
    package let rawValue: CXSourceRange
    private let owner: TranslationUnit

    package init(rawValue: CXSourceRange, owner: TranslationUnit) {
        self.rawValue = rawValue
        self.owner = owner
    }

    public var start: SourceLocation {
        SourceLocation(clang_getRangeStart(rawValue))
    }

    public var end: SourceLocation {
        SourceLocation(clang_getRangeEnd(rawValue))
    }

    public var tokens: [Token] {
        var pointer: UnsafeMutablePointer<CXToken>?
        var count: UInt32 = 0
        clang_tokenize(owner.rawValue, rawValue, &pointer, &count)

        guard let pointer, count > 0 else { return [] }
        defer { clang_disposeTokens(owner.rawValue, pointer, count) }

        return (0..<Int(count)).map { index in
            let rawToken = pointer[index]
            return Token(
                kind: .init(rawClangValue: CClang_tokenKind(rawToken)),
                spelling: clang_getTokenSpelling(owner.rawValue, rawToken).takeString()
            )
        }
    }
}
