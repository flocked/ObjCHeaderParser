import Foundation

/// A parsed Objective-C or C value backed by declaration source text.
public protocol ObjCSourceTextProviding {
    var info: ObjCDeclarationInfo { get }
}

public extension ObjCSourceTextProviding {
    /// The exact source text of the declaration, preserving whitespace and line breaks.
    var sourceText: String { info.sourceText }

    /// The token-normalized source text of the declaration.
    var normalizedSourceText: String { info.normalizedSourceText }

    /// The source text of the declaration header when the declaration contains a body.
    var headerText: String? { info.headerText }
}

extension ObjCClass: ObjCSourceTextProviding {}
extension ObjCProtocol: ObjCSourceTextProviding {}
extension ObjCCategory: ObjCSourceTextProviding {}
extension ObjCMethod: ObjCSourceTextProviding {}
extension ObjCProperty: ObjCSourceTextProviding {}
extension ObjCIvar: ObjCSourceTextProviding {}
extension ObjCEnum: ObjCSourceTextProviding {}
extension ObjCEnumCase: ObjCSourceTextProviding {}
extension ObjCField: ObjCSourceTextProviding {}
extension ObjCStruct: ObjCSourceTextProviding {}
extension ObjCUnion: ObjCSourceTextProviding {}
extension ObjCTypedef: ObjCSourceTextProviding {}
extension ObjCFunction: ObjCSourceTextProviding {}
extension ObjCVariable: ObjCSourceTextProviding {}
extension ObjCMacro: ObjCSourceTextProviding {}
extension ObjCInclude: ObjCSourceTextProviding {}
extension ObjCModuleImport: ObjCSourceTextProviding {}
extension ObjCForwardDeclaration: ObjCSourceTextProviding {}

public extension ObjCDeclaration {
    /// The exact source text of the declaration, preserving whitespace and line breaks.
    var sourceText: String {
        switch self {
        case .class(let value): value.sourceText
        case .protocol(let value): value.sourceText
        case .category(let value): value.sourceText
        case .enum(let value): value.sourceText
        case .struct(let value): value.sourceText
        case .union(let value): value.sourceText
        case .typedef(let value): value.sourceText
        case .function(let value): value.sourceText
        case .variable(let value): value.sourceText
        case .macro(let value): value.sourceText
        case .include(let value): value.sourceText
        case .moduleImport(let value): value.sourceText
        case .forwardDeclaration(let value): value.sourceText
        }
    }

    /// The token-normalized source text of the declaration.
    var normalizedSourceText: String {
        switch self {
        case .class(let value): value.normalizedSourceText
        case .protocol(let value): value.normalizedSourceText
        case .category(let value): value.normalizedSourceText
        case .enum(let value): value.normalizedSourceText
        case .struct(let value): value.normalizedSourceText
        case .union(let value): value.normalizedSourceText
        case .typedef(let value): value.normalizedSourceText
        case .function(let value): value.normalizedSourceText
        case .variable(let value): value.normalizedSourceText
        case .macro(let value): value.normalizedSourceText
        case .include(let value): value.normalizedSourceText
        case .moduleImport(let value): value.normalizedSourceText
        case .forwardDeclaration(let value): value.normalizedSourceText
        }
    }
}
