import CClang

public struct Token: Hashable, Sendable {
    public enum Kind: UInt32, Hashable, Sendable {
        case punctuation = 0
        case keyword = 1
        case identifier = 2
        case literal = 3
        case comment = 4
        case unknown = 255

        package init(rawClangValue: UInt32) {
            self = Self(rawValue: rawClangValue) ?? .unknown
        }
    }

    public let kind: Kind
    public let spelling: String

    package init(kind: Kind, spelling: String) {
        self.kind = kind
        self.spelling = spelling
    }
}
