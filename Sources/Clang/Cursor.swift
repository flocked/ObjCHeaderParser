import Foundation
import CClang

public struct Cursor: @unchecked Sendable {
    public struct Kind: RawRepresentable, Hashable, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let unexposedDecl = Self(rawValue: 1)
        public static let structDecl = Self(rawValue: 2)
        public static let unionDecl = Self(rawValue: 3)
        public static let classDecl = Self(rawValue: 4)
        public static let enumDecl = Self(rawValue: 5)
        public static let fieldDecl = Self(rawValue: 6)
        public static let enumConstantDecl = Self(rawValue: 7)
        public static let functionDecl = Self(rawValue: 8)
        public static let varDecl = Self(rawValue: 9)
        public static let parameterDecl = Self(rawValue: 10)
        public static let objcInterfaceDecl = Self(rawValue: 11)
        public static let objcCategoryDecl = Self(rawValue: 12)
        public static let objcProtocolDecl = Self(rawValue: 13)
        public static let objcPropertyDecl = Self(rawValue: 14)
        public static let objcIvarDecl = Self(rawValue: 15)
        public static let objcInstanceMethodDecl = Self(rawValue: 16)
        public static let objcClassMethodDecl = Self(rawValue: 17)
        public static let typedefDecl = Self(rawValue: 20)
        public static let cxxAccessSpecifier = Self(rawValue: 39)
        public static let objcSuperClassRef = Self(rawValue: 40)
        public static let objcProtocolRef = Self(rawValue: 41)
        public static let objcClassRef = Self(rawValue: 42)
        public static let macroDefinition = Self(rawValue: 501)
        public static let macroExpansion = Self(rawValue: 502)
        public static let inclusionDirective = Self(rawValue: 503)
        public static let moduleImportDecl = Self(rawValue: 600)
    }

    public enum AccessSpecifier: UInt32, Hashable, Sendable {
        case invalid = 0
        case `public` = 1
        case protected = 2
        case `private` = 3
        case unknown = 255

        package init(rawClangValue: UInt32) {
            self = Self(rawValue: rawClangValue) ?? .unknown
        }
    }

    package let rawValue: CXCursor
    package let ownerForPackage: TranslationUnit

    package init(rawValue: CXCursor, owner: TranslationUnit) {
        self.rawValue = rawValue
        self.ownerForPackage = owner
    }

    public var kind: Kind { Kind(rawValue: CClang_cursorKind(rawValue)) }
    public var kindSpelling: String { CClang_cursorKindSpelling(kind.rawValue).takeString() }
    public var spelling: String { clang_getCursorSpelling(rawValue).takeString() }
    public var displayName: String { clang_getCursorDisplayName(rawValue).takeString() }
    public var usr: String? {
        let value = clang_getCursorUSR(rawValue).takeString()
        return value.isEmpty ? nil : value
    }
    public var type: ClangType { ClangType(rawValue: clang_getCursorType(rawValue), owner: ownerForPackage) }
    public var resultType: ClangType? {
        let value = clang_getCursorResultType(rawValue)
        guard CClang_typeKind(value) != ClangType.Kind.invalid.rawValue else { return nil }
        return ClangType(rawValue: value, owner: ownerForPackage)
    }
    public var canonical: Self { Self(rawValue: clang_getCanonicalCursor(rawValue), owner: ownerForPackage) }
    public var referenced: Self? { optionalCursor(clang_getCursorReferenced(rawValue)) }
    public var definition: Self? { optionalCursor(clang_getCursorDefinition(rawValue)) }
    public var semanticParent: Self? { optionalCursor(clang_getCursorSemanticParent(rawValue)) }
    public var lexicalParent: Self? { optionalCursor(clang_getCursorLexicalParent(rawValue)) }
    public var isDefinition: Bool { clang_isCursorDefinition(rawValue) != 0 }
    public var isAttribute: Bool { CClang_cursorIsAttribute(rawValue) != 0 }
    public var isOptionalObjCDeclaration: Bool { clang_Cursor_isObjCOptional(rawValue) != 0 }
    public var isVariadic: Bool { clang_Cursor_isVariadic(rawValue) != 0 }
    public var isInlineFunction: Bool { clang_Cursor_isFunctionInlined(rawValue) != 0 }
    public var isFunctionLikeMacro: Bool { clang_Cursor_isMacroFunctionLike(rawValue) != 0 }
    public var isBuiltinMacro: Bool { clang_Cursor_isMacroBuiltin(rawValue) != 0 }
    public var hasGlobalStorage: Bool { clang_Cursor_hasVarDeclGlobalStorage(rawValue) != 0 }
    public var hasExternalStorage: Bool { clang_Cursor_hasVarDeclExternalStorage(rawValue) != 0 }
    public var isBitField: Bool { clang_Cursor_isBitField(rawValue) != 0 }
    public var bitWidth: Int? {
        guard isBitField else { return nil }
        let value = clang_getFieldDeclBitWidth(rawValue)
        return value < 0 ? nil : Int(value)
    }
    public var fieldOffset: Int64? {
        let value = clang_Cursor_getOffsetOfField(rawValue)
        return value < 0 ? nil : value
    }
    public var location: SourceLocation { SourceLocation(clang_getCursorLocation(rawValue)) }
    public var expansionLocation: SourceLocation { SourceLocation(clang_getCursorLocation(rawValue), resolution: .expansion) }
    public var fileLocation: SourceLocation { SourceLocation(clang_getCursorLocation(rawValue), resolution: .file) }
    public var extent: SourceRange { SourceRange(rawValue: clang_getCursorExtent(rawValue), owner: ownerForPackage) }
    public var rawComment: String? {
        let value = clang_Cursor_getRawCommentText(rawValue).takeString()
        return value.isEmpty ? nil : value
    }
    public var briefComment: String? {
        let value = clang_Cursor_getBriefCommentText(rawValue).takeString()
        return value.isEmpty ? nil : value
    }
    public var children: [Self] {
        final class Storage { var values: [CXCursor] = [] }
        let storage = Storage()
        let context = Unmanaged.passUnretained(storage).toOpaque()
        clang_visitChildren(rawValue, { cursor, _, context in
            guard let context else { return CXChildVisit_Continue }
            Unmanaged<Storage>.fromOpaque(context).takeUnretainedValue().values.append(cursor)
            return CXChildVisit_Continue
        }, context)
        return storage.values.map { Self(rawValue: $0, owner: ownerForPackage) }
    }
    public var arguments: [Self] {
        let count = clang_Cursor_getNumArguments(rawValue)
        guard count > 0 else { return [] }
        return (0..<count).compactMap { optionalCursor(clang_Cursor_getArgument(rawValue, UInt32($0))) }
    }
    public var objcSelectorIndex: Int? {
        let index = clang_Cursor_getObjCSelectorIndex(rawValue)
        return index < 0 ? nil : Int(index)
    }
    public var objcPropertyAttributesRawValue: UInt32 { clang_Cursor_getObjCPropertyAttributes(rawValue, 0) }
    public var objcPropertyGetterName: String? {
        let value = clang_Cursor_getObjCPropertyGetterName(rawValue).takeString()
        return value.isEmpty ? nil : value
    }
    public var objcPropertySetterName: String? {
        let value = clang_Cursor_getObjCPropertySetterName(rawValue).takeString()
        return value.isEmpty ? nil : value
    }
    public var objcDeclQualifiersRawValue: UInt32 { clang_Cursor_getObjCDeclQualifiers(rawValue) }
    public var objcAccessSpecifier: AccessSpecifier { AccessSpecifier(rawClangValue: CClang_cxxAccessSpecifier(rawValue)) }
    public var availability: Availability { Availability(cursor: rawValue) }
    public var linkageRawValue: UInt32 { CClang_cursorLinkage(rawValue) }
    public var visibilityRawValue: UInt32 { CClang_cursorVisibility(rawValue) }
    public var storageClassRawValue: UInt32 { CClang_cursorStorageClass(rawValue) }
    public var tlsKindRawValue: UInt32 { CClang_cursorTLSKind(rawValue) }
    public var isAnonymousRecord: Bool { clang_Cursor_isAnonymousRecordDecl(rawValue) != 0 }
    public var variableInitializer: Self? { optionalCursor(clang_Cursor_getVarDeclInitializer(rawValue)) }
    public var includedFile: URL? {
        guard let file = clang_getIncludedFile(rawValue) else { return nil }
        let path = clang_getFileName(file).takeString()
        return path.isEmpty ? nil : URL(fileURLWithPath: path)
    }
    public var enumIntegerType: ClangType? {
        let value = clang_getEnumDeclIntegerType(rawValue)
        guard CClang_typeKind(value) != ClangType.Kind.invalid.rawValue else { return nil }
        return ClangType(rawValue: value, owner: ownerForPackage)
    }
    public var enumSignedValue: Int64 { clang_getEnumConstantDeclValue(rawValue) }
    public var enumUnsignedValue: UInt64 { clang_getEnumConstantDeclUnsignedValue(rawValue) }
    public var overridden: [Self] {
        let count = CClang_overriddenCursorCount(rawValue)
        guard count > 0 else { return [] }
        return (0..<count).compactMap { optionalCursor(CClang_overriddenCursorAt(rawValue, $0)) }
    }

    private func optionalCursor(_ value: CXCursor) -> Self? {
        guard clang_Cursor_isNull(value) == 0 else { return nil }
        return Self(rawValue: value, owner: ownerForPackage)
    }
}
