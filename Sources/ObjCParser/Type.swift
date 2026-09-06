import Foundation

public struct ObjCType: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case invalid, unexposed, void, bool
        case char, signedChar, unsignedChar, short, unsignedShort, int, unsignedInt
        case long, unsignedLong, longLong, unsignedLongLong
        case int128, unsignedInt128
        case float, double, longDouble, half, float128
        case objcId, objcClass, objcSelector, objcInterface, objcObject, objcObjectPointer
        case pointer, blockPointer, functionNoPrototype, functionPrototype
        case constantArray, incompleteArray, variableArray, dependentSizedArray
        case vector, extendedVector
        case record, enumeration, typedef
        case elaborated, attributed, atomic, complex
        case other
    }

    public enum Nullability: String, Codable, Hashable, Sendable {
        case nonnull
        case nullable
        case unspecified
        case nullableResult
        case invalid
    }

    public enum Ownership: String, Codable, Hashable, Sendable {
        case strong
        case weak
        case autoreleasing
        case unsafeUnretained
    }

    public struct Qualifiers: OptionSet, Codable, Hashable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let `const` = Self(rawValue: 1 << 0)
        public static let volatile = Self(rawValue: 1 << 1)
        public static let restrict = Self(rawValue: 1 << 2)
    }

    public let kind: Kind
    public let clangKindRawValue: UInt32
    public let spelling: String
    public let canonicalSpelling: String
    public let nullability: Nullability?
    public let ownership: Ownership?
    public let isKindOf: Bool
    public let qualifiers: Qualifiers
    public let declarationUSR: String?
    public let declarationName: String?
    public let pointeeType: Indirect<ObjCType>?
    public let elementType: Indirect<ObjCType>?
    public let resultType: Indirect<ObjCType>?
    public let parameterTypes: [ObjCType]
    public let typeArguments: [ObjCType]
    public let protocols: [String]
    public let arraySize: Int64?
    public let size: Int64?
    public let alignment: Int64?
    public let isVariadic: Bool
    public let callingConvention: ObjCCallingConvention?

    public init(
        kind: Kind,
        clangKindRawValue: UInt32 = 0,
        spelling: String,
        canonicalSpelling: String,
        nullability: Nullability? = nil,
        ownership: Ownership? = nil,
        isKindOf: Bool = false,
        qualifiers: Qualifiers = [],
        declarationUSR: String? = nil,
        declarationName: String? = nil,
        pointeeType: ObjCType? = nil,
        elementType: ObjCType? = nil,
        resultType: ObjCType? = nil,
        parameterTypes: [ObjCType] = [],
        typeArguments: [ObjCType] = [],
        protocols: [String] = [],
        arraySize: Int64? = nil,
        size: Int64? = nil,
        alignment: Int64? = nil,
        isVariadic: Bool = false,
        callingConvention: ObjCCallingConvention? = nil
    ) {
        self.kind = kind
        self.clangKindRawValue = clangKindRawValue
        self.spelling = spelling
        self.canonicalSpelling = canonicalSpelling
        self.nullability = nullability
        self.ownership = ownership
        self.isKindOf = isKindOf
        self.qualifiers = qualifiers
        self.declarationUSR = declarationUSR
        self.declarationName = declarationName
        self.pointeeType = pointeeType.map(Indirect.init)
        self.elementType = elementType.map(Indirect.init)
        self.resultType = resultType.map(Indirect.init)
        self.parameterTypes = parameterTypes
        self.typeArguments = typeArguments
        self.protocols = protocols
        self.arraySize = arraySize
        self.size = size
        self.alignment = alignment
        self.isVariadic = isVariadic
        self.callingConvention = callingConvention
    }
}
