import Foundation

public enum ObjCMethodKind: String, Codable, Hashable, Sendable {
    case instance
    case `class`
}

public struct ObjCMethod: Codable, Hashable, Sendable {
    public enum Family: String, Codable, Hashable, Sendable { case none, alloc, initFamily, copy, mutableCopy, new }
    public let info: ObjCDeclarationInfo
    public let selector: String
    public let kind: ObjCMethodKind
    public let returnType: ObjCType
    public let returnQualifiers: ObjCDeclQualifiers
    public let parameters: [ObjCParameter]
    public let isVariadic: Bool
    public let isOptional: Bool
    public let family: Family
    public let overriddenMethods: [ObjCDeclarationReference]

    public init(
        info: ObjCDeclarationInfo,
        selector: String,
        kind: ObjCMethodKind,
        returnType: ObjCType,
        returnQualifiers: ObjCDeclQualifiers = [],
        parameters: [ObjCParameter],
        isVariadic: Bool,
        isOptional: Bool,
        family: Family = .none,
        overriddenMethods: [ObjCDeclarationReference] = []
    ) {
        self.info = info
        self.selector = selector
        self.kind = kind
        self.returnType = returnType
        self.returnQualifiers = returnQualifiers
        self.parameters = parameters
        self.isVariadic = isVariadic
        self.isOptional = isOptional
        self.family = family
        self.overriddenMethods = overriddenMethods
    }
}

public struct ObjCParameter: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo?
    public let name: String?
    public let type: ObjCType
    public let qualifiers: ObjCDeclQualifiers

    /// The exact source text of the parameter declaration when available.
    public var sourceText: String? { info?.sourceText }

    public init(info: ObjCDeclarationInfo? = nil, name: String?, type: ObjCType, qualifiers: ObjCDeclQualifiers = []) {
        self.info = info
        self.name = name
        self.type = type
        self.qualifiers = qualifiers
    }
}

public struct ObjCDeclQualifiers: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let `in` = Self(rawValue: 1 << 0)
    public static let inoutQualifier = Self(rawValue: 1 << 1)
    public static let out = Self(rawValue: 1 << 2)
    public static let bycopy = Self(rawValue: 1 << 3)
    public static let byref = Self(rawValue: 1 << 4)
    public static let oneway = Self(rawValue: 1 << 5)
}

public struct ObjCPropertyAttributes: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt16

    public init(rawValue: UInt16) { self.rawValue = rawValue }

    public static let readonly = Self(rawValue: 1 << 0)
    public static let getter = Self(rawValue: 1 << 1)
    public static let assign = Self(rawValue: 1 << 2)
    public static let readwrite = Self(rawValue: 1 << 3)
    public static let retain = Self(rawValue: 1 << 4)
    public static let copy = Self(rawValue: 1 << 5)
    public static let nonatomic = Self(rawValue: 1 << 6)
    public static let setter = Self(rawValue: 1 << 7)
    public static let atomic = Self(rawValue: 1 << 8)
    public static let weak = Self(rawValue: 1 << 9)
    public static let strong = Self(rawValue: 1 << 10)
    public static let unsafeUnretained = Self(rawValue: 1 << 11)
    public static let classProperty = Self(rawValue: 1 << 12)
}

public struct ObjCProperty: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let type: ObjCType
    public let attributes: ObjCPropertyAttributes
    public let getter: String
    public let setter: String?
    public let isClassProperty: Bool
    public let isOptional: Bool

    public init(
        info: ObjCDeclarationInfo,
        name: String,
        type: ObjCType,
        attributes: ObjCPropertyAttributes,
        getter: String,
        setter: String?,
        isClassProperty: Bool,
        isOptional: Bool
    ) {
        self.info = info
        self.name = name
        self.type = type
        self.attributes = attributes
        self.getter = getter
        self.setter = setter
        self.isClassProperty = isClassProperty
        self.isOptional = isOptional
    }
}

public struct ObjCIvar: Codable, Hashable, Sendable {
    public enum AccessControl: String, Codable, Hashable, Sendable {
        case `private`, protected, `public`, package, none
    }

    public let info: ObjCDeclarationInfo
    public let name: String
    public let type: ObjCType
    public let accessControl: AccessControl
    public let offset: Int64?

    public init(info: ObjCDeclarationInfo, name: String, type: ObjCType, accessControl: AccessControl, offset: Int64?) {
        self.info = info
        self.name = name
        self.type = type
        self.accessControl = accessControl
        self.offset = offset
    }
}
