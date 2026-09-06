import Foundation

public struct ObjCEnum: Codable, Hashable, Sendable {
    public enum Style: String, Codable, Hashable, Sendable { case plain, `enum`, options, error }
    public let info: ObjCDeclarationInfo
    public let name: String?
    public let underlyingType: ObjCType?
    public let cases: [ObjCEnumCase]
    public let style: Style

    public init(info: ObjCDeclarationInfo, name: String?, underlyingType: ObjCType?, cases: [ObjCEnumCase], style: Style = .plain) {
        self.info = info; self.name = name; self.underlyingType = underlyingType; self.cases = cases; self.style = style
    }
}

public struct ObjCEnumCase: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let signedValue: Int64
    public let unsignedValue: UInt64
    public let expression: String?

    public init(info: ObjCDeclarationInfo, name: String, signedValue: Int64, unsignedValue: UInt64, expression: String? = nil) {
        self.info = info; self.name = name; self.signedValue = signedValue; self.unsignedValue = unsignedValue; self.expression = expression
    }
}

public struct ObjCField: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String?
    public let type: ObjCType
    public let offset: Int64?
    public let bitWidth: Int?
    public let bitWidthExpression: String?

    public init(info: ObjCDeclarationInfo, name: String?, type: ObjCType, offset: Int64?, bitWidth: Int?, bitWidthExpression: String? = nil) {
        self.info = info; self.name = name; self.type = type; self.offset = offset; self.bitWidth = bitWidth; self.bitWidthExpression = bitWidthExpression
    }
}

public struct ObjCStruct: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String?
    public let fields: [ObjCField]
    public let size: Int64?
    public let alignment: Int64?
    public let isAnonymous: Bool
    public init(info: ObjCDeclarationInfo, name: String?, fields: [ObjCField], size: Int64?, alignment: Int64?, isAnonymous: Bool = false) {
        self.info = info; self.name = name; self.fields = fields; self.size = size; self.alignment = alignment; self.isAnonymous = isAnonymous
    }
}

public struct ObjCUnion: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String?
    public let fields: [ObjCField]
    public let size: Int64?
    public let alignment: Int64?
    public let isAnonymous: Bool
    public init(info: ObjCDeclarationInfo, name: String?, fields: [ObjCField], size: Int64?, alignment: Int64?, isAnonymous: Bool = false) {
        self.info = info; self.name = name; self.fields = fields; self.size = size; self.alignment = alignment; self.isAnonymous = isAnonymous
    }
}

public struct ObjCTypedef: Codable, Hashable, Sendable {
    public enum Style: String, Codable, Hashable, Sendable {
        case plain, `enum`, options, errorEnum, typedEnum, typedExtensibleEnum, extensibleStringEnum
    }
    public let info: ObjCDeclarationInfo
    public let name: String
    public let underlyingType: ObjCType
    public let canonicalType: ObjCType
    public let associatedDeclaration: ObjCDeclarationReference?
    public let style: Style

    public init(info: ObjCDeclarationInfo, name: String, underlyingType: ObjCType, canonicalType: ObjCType, associatedDeclaration: ObjCDeclarationReference? = nil, style: Style = .plain) {
        self.info = info; self.name = name; self.underlyingType = underlyingType; self.canonicalType = canonicalType; self.associatedDeclaration = associatedDeclaration; self.style = style
    }
}

public struct ObjCFunction: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let returnType: ObjCType
    public let parameters: [ObjCParameter]
    public let isVariadic: Bool
    public let isInline: Bool
    public let storageClass: ObjCStorageClass
    public let callingConvention: ObjCCallingConvention?
    public init(info: ObjCDeclarationInfo, name: String, returnType: ObjCType, parameters: [ObjCParameter], isVariadic: Bool, isInline: Bool, storageClass: ObjCStorageClass = .invalid, callingConvention: ObjCCallingConvention? = nil) {
        self.info = info; self.name = name; self.returnType = returnType; self.parameters = parameters; self.isVariadic = isVariadic; self.isInline = isInline; self.storageClass = storageClass; self.callingConvention = callingConvention
    }
}

public struct ObjCVariable: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let type: ObjCType
    public let hasGlobalStorage: Bool
    public let hasExternalStorage: Bool
    public let storageClass: ObjCStorageClass
    public let tlsKind: ObjCTLSKind
    public let initializer: String?
    public init(info: ObjCDeclarationInfo, name: String, type: ObjCType, hasGlobalStorage: Bool, hasExternalStorage: Bool, storageClass: ObjCStorageClass = .invalid, tlsKind: ObjCTLSKind = .none, initializer: String? = nil) {
        self.info = info; self.name = name; self.type = type; self.hasGlobalStorage = hasGlobalStorage; self.hasExternalStorage = hasExternalStorage; self.storageClass = storageClass; self.tlsKind = tlsKind; self.initializer = initializer
    }
}

public struct ObjCMacro: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let definition: String
    public let isFunctionLike: Bool
    public let isBuiltin: Bool
    public let parameters: [String]
    public let replacementTokens: [String]
    public let isVariadic: Bool
    public init(info: ObjCDeclarationInfo, name: String, definition: String, isFunctionLike: Bool, isBuiltin: Bool, parameters: [String] = [], replacementTokens: [String] = [], isVariadic: Bool = false) {
        self.info = info; self.name = name; self.definition = definition; self.isFunctionLike = isFunctionLike; self.isBuiltin = isBuiltin; self.parameters = parameters; self.replacementTokens = replacementTokens; self.isVariadic = isVariadic
    }
}

public struct ObjCInclude: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let spelling: String
    public let resolvedURL: URL?
    public let isImport: Bool
    public let isAngled: Bool
    public init(info: ObjCDeclarationInfo, spelling: String, resolvedURL: URL?, isImport: Bool, isAngled: Bool) {
        self.info = info; self.spelling = spelling; self.resolvedURL = resolvedURL; self.isImport = isImport; self.isAngled = isAngled
    }
}

public struct ObjCModuleImport: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let moduleName: String
    public init(info: ObjCDeclarationInfo, moduleName: String) { self.info = info; self.moduleName = moduleName }
}
