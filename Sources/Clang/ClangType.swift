import CClang

public struct ClangType: @unchecked Sendable {
    public struct Kind: RawRepresentable, Hashable, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) { self.rawValue = rawValue }

        public static let invalid = Self(rawValue: 0)
        public static let unexposed = Self(rawValue: 1)
        public static let void = Self(rawValue: 2)
        public static let bool = Self(rawValue: 3)
        public static let charU = Self(rawValue: 4)
        public static let uChar = Self(rawValue: 5)
        public static let uShort = Self(rawValue: 8)
        public static let uInt = Self(rawValue: 9)
        public static let uLong = Self(rawValue: 10)
        public static let uLongLong = Self(rawValue: 11)
        public static let uInt128 = Self(rawValue: 12)
        public static let charS = Self(rawValue: 13)
        public static let sChar = Self(rawValue: 14)
        public static let short = Self(rawValue: 16)
        public static let int = Self(rawValue: 17)
        public static let long = Self(rawValue: 18)
        public static let longLong = Self(rawValue: 19)
        public static let int128 = Self(rawValue: 20)
        public static let float = Self(rawValue: 21)
        public static let double = Self(rawValue: 22)
        public static let longDouble = Self(rawValue: 23)
        public static let objcId = Self(rawValue: 27)
        public static let objcClass = Self(rawValue: 28)
        public static let objcSel = Self(rawValue: 29)
        public static let float128 = Self(rawValue: 30)
        public static let half = Self(rawValue: 31)
        public static let complex = Self(rawValue: 100)
        public static let pointer = Self(rawValue: 101)
        public static let blockPointer = Self(rawValue: 102)
        public static let record = Self(rawValue: 105)
        public static let enumeration = Self(rawValue: 106)
        public static let typedef = Self(rawValue: 107)
        public static let objcInterface = Self(rawValue: 108)
        public static let objcObjectPointer = Self(rawValue: 109)
        public static let functionNoPrototype = Self(rawValue: 110)
        public static let functionPrototype = Self(rawValue: 111)
        public static let constantArray = Self(rawValue: 112)
        public static let vector = Self(rawValue: 113)
        public static let incompleteArray = Self(rawValue: 114)
        public static let variableArray = Self(rawValue: 115)
        public static let dependentSizedArray = Self(rawValue: 116)
        public static let objcObject = Self(rawValue: 161)
        public static let attributed = Self(rawValue: 163)
        public static let extendedVector = Self(rawValue: 176)
        public static let atomic = Self(rawValue: 177)
        public static let elaborated = Self(rawValue: 119)
    }

    public enum Nullability: UInt32, Hashable, Sendable {
        case nonnull = 0
        case nullable = 1
        case unspecified = 2
        case invalid = 3
        case nullableResult = 4
        case unknown = 255

        package init(rawClangValue: UInt32) {
            self = Self(rawValue: rawClangValue) ?? .unknown
        }
    }

    package let rawValue: CXType
    private let owner: TranslationUnit

    package init(rawValue: CXType, owner: TranslationUnit) {
        self.rawValue = rawValue
        self.owner = owner
    }

    public var kind: Kind { Kind(rawValue: CClang_typeKind(rawValue)) }
    public var spelling: String { clang_getTypeSpelling(rawValue).takeString() }
    public var canonical: Self { Self(rawValue: clang_getCanonicalType(rawValue), owner: owner) }
    public var pointee: Self? { optionalType(clang_getPointeeType(rawValue)) }
    public var result: Self? { optionalType(clang_getResultType(rawValue)) }
    public var declaration: Cursor? {
        let cursor = clang_getTypeDeclaration(rawValue)
        guard clang_Cursor_isNull(cursor) == 0 else { return nil }
        return Cursor(rawValue: cursor, owner: owner)
    }
    public var nullability: Nullability { Nullability(rawClangValue: CClang_typeNullability(rawValue)) }
    public var argumentTypes: [Self] {
        let count = clang_getNumArgTypes(rawValue)
        guard count > 0 else { return [] }
        return (0..<count).compactMap { optionalType(clang_getArgType(rawValue, UInt32($0))) }
    }
    public var arrayElementType: Self? { optionalType(clang_getArrayElementType(rawValue)) }
    public var elementType: Self? { optionalType(clang_getElementType(rawValue)) }
    public var arraySize: Int64? {
        let value = clang_getArraySize(rawValue)
        return value < 0 ? nil : value
    }
    public var size: Int64? {
        let value = clang_Type_getSizeOf(rawValue)
        return value < 0 ? nil : value
    }
    public var alignment: Int64? {
        let value = clang_Type_getAlignOf(rawValue)
        return value < 0 ? nil : value
    }
    public var isConstQualified: Bool { clang_isConstQualifiedType(rawValue) != 0 }
    public var isVolatileQualified: Bool { clang_isVolatileQualifiedType(rawValue) != 0 }
    public var isRestrictQualified: Bool { clang_isRestrictQualifiedType(rawValue) != 0 }
    public var isVariadic: Bool { clang_isFunctionTypeVariadic(rawValue) != 0 }
    public var callingConventionRawValue: UInt32 { CClang_typeCallingConvention(rawValue) }
    public var objcProtocolDeclarations: [Cursor] {
        let count = clang_Type_getNumObjCProtocolRefs(rawValue)
        guard count > 0 else { return [] }
        return (0..<count).compactMap { index in
            let cursor = clang_Type_getObjCProtocolDecl(rawValue, UInt32(index))
            guard clang_Cursor_isNull(cursor) == 0 else { return nil }
            return Cursor(rawValue: cursor, owner: owner)
        }
    }
    public var objcTypeArguments: [Self] {
        let count = clang_Type_getNumObjCTypeArgs(rawValue)
        guard count > 0 else { return [] }
        return (0..<count).compactMap { optionalType(clang_Type_getObjCTypeArg(rawValue, UInt32($0))) }
    }

    private func optionalType(_ value: CXType) -> Self? {
        guard CClang_typeKind(value) != Kind.invalid.rawValue else { return nil }
        return Self(rawValue: value, owner: owner)
    }
}
