import Foundation

public struct ObjCHeader: Codable, Hashable, Sendable {
    public struct ParseContext: Codable, Hashable, Sendable {
        public let sdk: URL?
        public let target: String?
        public let clangArguments: [String]
        public init(sdk: URL? = nil, target: String? = nil, clangArguments: [String] = []) {
            self.sdk = sdk; self.target = target; self.clangArguments = clangArguments
        }
    }

    public let url: URL
    /// The complete source text of the parsed header when it could be decoded as UTF-8.
    public let sourceText: String?
    public let declarations: [ObjCDeclaration]
    public let parseContext: ParseContext?

    public init(url: URL, sourceText: String? = nil, declarations: [ObjCDeclaration], parseContext: ParseContext? = nil) {
        self.url = url; self.sourceText = sourceText; self.declarations = declarations; self.parseContext = parseContext
    }

    public var classes: [ObjCClass] { declarations.compactMap { if case .class(let value) = $0 { value } else { nil } } }
    public var protocols: [ObjCProtocol] { declarations.compactMap { if case .protocol(let value) = $0 { value } else { nil } } }
    public var categories: [ObjCCategory] { declarations.compactMap { if case .category(let value) = $0 { value } else { nil } } }
    public var enums: [ObjCEnum] { declarations.compactMap { if case .enum(let value) = $0 { value } else { nil } } }
    public var structs: [ObjCStruct] { declarations.compactMap { if case .struct(let value) = $0 { value } else { nil } } }
    public var unions: [ObjCUnion] { declarations.compactMap { if case .union(let value) = $0 { value } else { nil } } }
    public var typedefs: [ObjCTypedef] { declarations.compactMap { if case .typedef(let value) = $0 { value } else { nil } } }
    public var functions: [ObjCFunction] { declarations.compactMap { if case .function(let value) = $0 { value } else { nil } } }
    public var variables: [ObjCVariable] { declarations.compactMap { if case .variable(let value) = $0 { value } else { nil } } }
    public var macros: [ObjCMacro] { declarations.compactMap { if case .macro(let value) = $0 { value } else { nil } } }
    public var includes: [ObjCInclude] { declarations.compactMap { if case .include(let value) = $0 { value } else { nil } } }
    public var moduleImports: [ObjCModuleImport] { declarations.compactMap { if case .moduleImport(let value) = $0 { value } else { nil } } }
    public var forwardDeclarations: [ObjCForwardDeclaration] { declarations.compactMap { if case .forwardDeclaration(let value) = $0 { value } else { nil } } }
}

public extension ObjCHeader {
    func categories(for className: String) -> [ObjCCategory] { categories.filter { $0.classReference.name == className } }
    func allMethods(for className: String) -> [ObjCMethod] {
        guard let cls = classes.first(where: { $0.name == className }) else { return [] }
        return cls.methods + categories(for: className).flatMap(\.methods)
    }
    func allProperties(for className: String) -> [ObjCProperty] {
        guard let cls = classes.first(where: { $0.name == className }) else { return [] }
        return cls.properties + categories(for: className).flatMap(\.properties)
    }
}
