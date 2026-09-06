import CClang

public struct Availability: Hashable, Sendable {
    public enum Kind: UInt32, Hashable, Sendable {
        case available = 0
        case deprecated = 1
        case notAvailable = 2
        case notAccessible = 3
        case unknown = 255

        package init(rawClangValue: UInt32) {
            self = Self(rawValue: rawClangValue) ?? .unknown
        }
    }

    public let kind: Kind

    package init(cursor: CXCursor) {
        kind = Kind(rawClangValue: CClang_cursorAvailability(cursor))
    }
}
