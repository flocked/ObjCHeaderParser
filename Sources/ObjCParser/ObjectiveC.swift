import Foundation

public struct ObjCTypeReference: Codable, Hashable, Sendable {
    public let name: String
    public let usr: String?

    public init(name: String, usr: String? = nil) {
        self.name = name
        self.usr = usr
    }
}

public typealias ObjCProtocolReference = ObjCTypeReference


public struct ObjCGenericParameter: Codable, Hashable, Sendable {
    public enum Variance: String, Codable, Hashable, Sendable { case invariant, covariant, contravariant }
    public let name: String
    public let variance: Variance
    public let bound: String?
    public init(name: String, variance: Variance = .invariant, bound: String? = nil) {
        self.name = name; self.variance = variance; self.bound = bound
    }
}

public struct ObjCClass: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let superclass: ObjCTypeReference?
    public let protocols: [ObjCProtocolReference]
    public let properties: [ObjCProperty]
    public let methods: [ObjCMethod]
    public let ivars: [ObjCIvar]
    public let genericParameters: [ObjCGenericParameter]

    public init(
        info: ObjCDeclarationInfo,
        name: String,
        superclass: ObjCTypeReference?,
        protocols: [ObjCProtocolReference],
        properties: [ObjCProperty],
        methods: [ObjCMethod],
        ivars: [ObjCIvar],
        genericParameters: [ObjCGenericParameter] = []
    ) {
        self.info = info
        self.name = name
        self.superclass = superclass
        self.protocols = protocols
        self.properties = properties
        self.methods = methods
        self.ivars = ivars
        self.genericParameters = genericParameters
    }
}

public struct ObjCProtocol: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String
    public let inheritedProtocols: [ObjCProtocolReference]
    public let methods: [ObjCMethod]
    public let properties: [ObjCProperty]

    public var requiredMethods: [ObjCMethod] { methods.filter { !$0.isOptional } }
    public var optionalMethods: [ObjCMethod] { methods.filter(\.isOptional) }
    public var requiredProperties: [ObjCProperty] { properties.filter { !$0.isOptional } }
    public var optionalProperties: [ObjCProperty] { properties.filter(\.isOptional) }

    public init(
        info: ObjCDeclarationInfo,
        name: String,
        inheritedProtocols: [ObjCProtocolReference],
        methods: [ObjCMethod],
        properties: [ObjCProperty]
    ) {
        self.info = info
        self.name = name
        self.inheritedProtocols = inheritedProtocols
        self.methods = methods
        self.properties = properties
    }
}

public struct ObjCCategory: Codable, Hashable, Sendable {
    public let info: ObjCDeclarationInfo
    public let name: String?
    public let classReference: ObjCTypeReference
    public let protocols: [ObjCProtocolReference]
    public let properties: [ObjCProperty]
    public let methods: [ObjCMethod]

    public init(
        info: ObjCDeclarationInfo,
        name: String?,
        classReference: ObjCTypeReference,
        protocols: [ObjCProtocolReference],
        properties: [ObjCProperty],
        methods: [ObjCMethod]
    ) {
        self.info = info
        self.name = name
        self.classReference = classReference
        self.protocols = protocols
        self.properties = properties
        self.methods = methods
    }
}
