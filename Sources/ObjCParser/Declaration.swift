import Foundation

public struct ObjCDeclarationInfo: Codable, Hashable, Sendable {
    public let name: String?
    public let usr: String?
    /// The exact source text covered by the declaration, preserving whitespace and line breaks.
    public let sourceText: String
    /// A token-normalized representation of the declaration.
    public let normalizedSourceText: String
    /// The source text for the declaration header when the declaration has a body, such as an Objective-C class, protocol, or category.
    public let headerText: String?
    public let location: ObjCSourceLocation
    public let expansionLocation: ObjCSourceLocation
    public let extent: ObjCSourceRange
    public let availability: ObjCGeneralAvailability
    public let platformAvailability: [ObjCAvailability]
    public let attributes: [ObjCAttribute]
    public let documentation: ObjCDocumentation?
    public let isDefinition: Bool
    public let canonical: ObjCDeclarationReference?
    public let semanticParent: ObjCDeclarationReference?
    public let lexicalParent: ObjCDeclarationReference?
    public let referenced: ObjCDeclarationReference?
    public let definition: ObjCDeclarationReference?
    public let linkage: ObjCLinkage
    public let visibility: ObjCVisibility

    /// The exact source text of the declaration.
    public var declaration: String { sourceText }

    /// The token-normalized source text of the declaration.
    public var normalizedDeclaration: String { normalizedSourceText }

    public init(
        name: String?,
        usr: String?,
        sourceText: String,
        normalizedSourceText: String? = nil,
        headerText: String? = nil,
        location: ObjCSourceLocation,
        expansionLocation: ObjCSourceLocation? = nil,
        extent: ObjCSourceRange,
        availability: ObjCGeneralAvailability,
        platformAvailability: [ObjCAvailability] = [],
        attributes: [ObjCAttribute] = [],
        documentation: ObjCDocumentation? = nil,
        isDefinition: Bool = false,
        canonical: ObjCDeclarationReference? = nil,
        semanticParent: ObjCDeclarationReference? = nil,
        lexicalParent: ObjCDeclarationReference? = nil,
        referenced: ObjCDeclarationReference? = nil,
        definition: ObjCDeclarationReference? = nil,
        linkage: ObjCLinkage = .invalid,
        visibility: ObjCVisibility = .invalid
    ) {
        self.name = name
        self.usr = usr
        self.sourceText = sourceText
        self.normalizedSourceText = normalizedSourceText ?? sourceText
        self.headerText = headerText
        self.location = location
        self.expansionLocation = expansionLocation ?? location
        self.extent = extent
        self.availability = availability
        self.platformAvailability = platformAvailability
        self.attributes = attributes
        self.documentation = documentation
        self.isDefinition = isDefinition
        self.canonical = canonical
        self.semanticParent = semanticParent
        self.lexicalParent = lexicalParent
        self.referenced = referenced
        self.definition = definition
        self.linkage = linkage
        self.visibility = visibility
    }

    @available(*, deprecated, renamed: "init(name:usr:sourceText:normalizedSourceText:headerText:location:expansionLocation:extent:availability:platformAvailability:attributes:documentation:isDefinition:canonical:semanticParent:lexicalParent:referenced:definition:linkage:visibility:)")
    public init(
        name: String?,
        usr: String?,
        declaration: String,
        normalizedDeclaration: String? = nil,
        location: ObjCSourceLocation,
        expansionLocation: ObjCSourceLocation? = nil,
        extent: ObjCSourceRange,
        availability: ObjCGeneralAvailability,
        platformAvailability: [ObjCAvailability] = [],
        attributes: [ObjCAttribute] = [],
        documentation: ObjCDocumentation? = nil,
        isDefinition: Bool = false,
        canonical: ObjCDeclarationReference? = nil,
        semanticParent: ObjCDeclarationReference? = nil,
        lexicalParent: ObjCDeclarationReference? = nil,
        referenced: ObjCDeclarationReference? = nil,
        definition: ObjCDeclarationReference? = nil,
        linkage: ObjCLinkage = .invalid,
        visibility: ObjCVisibility = .invalid
    ) {
        self.init(
            name: name,
            usr: usr,
            sourceText: declaration,
            normalizedSourceText: normalizedDeclaration,
            location: location,
            expansionLocation: expansionLocation,
            extent: extent,
            availability: availability,
            platformAvailability: platformAvailability,
            attributes: attributes,
            documentation: documentation,
            isDefinition: isDefinition,
            canonical: canonical,
            semanticParent: semanticParent,
            lexicalParent: lexicalParent,
            referenced: referenced,
            definition: definition,
            linkage: linkage,
            visibility: visibility
        )
    }
}

public struct ObjCAttribute: Codable, Hashable, Sendable {
    public struct Kind: RawRepresentable, Codable, Hashable, Sendable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
        public static let unexposed = Self(rawValue: 400)
        public static let ibAction = Self(rawValue: 401)
        public static let ibOutlet = Self(rawValue: 402)
        public static let ibOutletCollection = Self(rawValue: 403)
        public static let annotate = Self(rawValue: 406)
        public static let packed = Self(rawValue: 408)
        public static let pure = Self(rawValue: 409)
        public static let const = Self(rawValue: 410)
        public static let visibility = Self(rawValue: 417)
        public static let nsReturnsRetained = Self(rawValue: 420)
        public static let nsReturnsNotRetained = Self(rawValue: 421)
        public static let nsReturnsAutoreleased = Self(rawValue: 422)
        public static let nsConsumesSelf = Self(rawValue: 423)
        public static let nsConsumed = Self(rawValue: 424)
        public static let objcPreciseLifetime = Self(rawValue: 428)
        public static let objcReturnsInnerPointer = Self(rawValue: 429)
        public static let objcRequiresSuper = Self(rawValue: 430)
        public static let objcRootClass = Self(rawValue: 431)
        public static let objcSubclassingRestricted = Self(rawValue: 432)
        public static let objcDesignatedInitializer = Self(rawValue: 434)
        public static let objcRuntimeVisible = Self(rawValue: 435)
        public static let objcBoxable = Self(rawValue: 436)
        public static let flagEnum = Self(rawValue: 437)
        public static let warnUnused = Self(rawValue: 439)
        public static let warnUnusedResult = Self(rawValue: 440)
        public static let aligned = Self(rawValue: 441)
    }

    public let kind: Kind
    public let kindSpelling: String
    public let spelling: String
    /// The exact source text of the attribute cursor.
    public let sourceText: String

    /// The exact source text of the attribute cursor.
    public var declaration: String { sourceText }

    public init(kind: Kind, kindSpelling: String, spelling: String, sourceText: String) {
        self.kind = kind
        self.kindSpelling = kindSpelling
        self.spelling = spelling
        self.sourceText = sourceText
    }

    @available(*, deprecated, renamed: "init(kind:kindSpelling:spelling:sourceText:)")
    public init(kind: Kind, kindSpelling: String, spelling: String, declaration: String) {
        self.init(kind: kind, kindSpelling: kindSpelling, spelling: spelling, sourceText: declaration)
    }
}

public struct ObjCForwardDeclaration: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable { case `class`, `protocol` }
    public let info: ObjCDeclarationInfo
    public let kind: Kind
    public let name: String
    public init(info: ObjCDeclarationInfo, kind: Kind, name: String) { self.info = info; self.kind = kind; self.name = name }
}

public enum ObjCDeclaration: Codable, Hashable, Sendable {
    case `class`(ObjCClass)
    case `protocol`(ObjCProtocol)
    case category(ObjCCategory)
    case `enum`(ObjCEnum)
    case `struct`(ObjCStruct)
    case union(ObjCUnion)
    case typedef(ObjCTypedef)
    case function(ObjCFunction)
    case variable(ObjCVariable)
    case macro(ObjCMacro)
    case include(ObjCInclude)
    case moduleImport(ObjCModuleImport)
    case forwardDeclaration(ObjCForwardDeclaration)
}
