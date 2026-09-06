import Foundation

public struct ObjCLinkage: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let invalid = Self(rawValue: 0)
    public static let none = Self(rawValue: 1)
    public static let `internal` = Self(rawValue: 2)
    public static let uniqueExternal = Self(rawValue: 3)
    public static let external = Self(rawValue: 4)
}

public struct ObjCVisibility: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let invalid = Self(rawValue: 0)
    public static let hidden = Self(rawValue: 1)
    public static let protected = Self(rawValue: 2)
    public static let `default` = Self(rawValue: 3)
}

public struct ObjCStorageClass: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let invalid = Self(rawValue: 0)
    public static let none = Self(rawValue: 1)
    public static let `extern` = Self(rawValue: 2)
    public static let `static` = Self(rawValue: 3)
    public static let privateExtern = Self(rawValue: 4)
    public static let openCLWorkGroupLocal = Self(rawValue: 5)
    public static let auto = Self(rawValue: 6)
    public static let register = Self(rawValue: 7)
}

public struct ObjCTLSKind: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let none = Self(rawValue: 0)
    public static let `dynamic` = Self(rawValue: 1)
    public static let `static` = Self(rawValue: 2)
}

public struct ObjCCallingConvention: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let `default` = Self(rawValue: 0)
    public static let c = Self(rawValue: 1)
}

public struct ObjCDeclarationReference: Codable, Hashable, Sendable {
    public let name: String?
    public let usr: String?

    public init(name: String? = nil, usr: String? = nil) {
        self.name = name
        self.usr = usr
    }
}
