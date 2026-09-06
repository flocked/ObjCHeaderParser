import Foundation
import Clang
import CClang

public struct ObjCExtractor {
    private let sourceCache: SourceFileCache

    public init() {
        sourceCache = SourceFileCache()
    }

    public func extract(
        from translationUnit: TranslationUnit,
        sourceURL: URL,
        includeIncludedHeaders: Bool = false,
        parseContext: ObjCHeader.ParseContext? = nil
    ) -> ObjCHeader {
        let sourcePath = sourceURL.standardizedFileURL.path
        let declarations = translationUnit.cursor.children
            .filter { cursor in
                guard !includeIncludedHeaders else { return true }
                return cursor.location.file?.standardizedFileURL.path == sourcePath
            }
            .compactMap(makeDeclaration)
        return ObjCHeader(
            url: sourceURL,
            sourceText: sourceCache.string(for: sourceURL),
            declarations: declarations,
            parseContext: parseContext
        )
    }

    private func makeDeclaration(_ cursor: Cursor) -> ObjCDeclaration? {
        switch cursor.kind {
        case .objcInterfaceDecl: return makeClass(cursor).map(ObjCDeclaration.class)
        case .objcProtocolDecl: return makeProtocol(cursor).map(ObjCDeclaration.protocol)
        case .objcCategoryDecl: return makeCategory(cursor).map(ObjCDeclaration.category)
        case .enumDecl: return .enum(makeEnum(cursor))
        case .structDecl: return .struct(makeStruct(cursor))
        case .unionDecl: return .union(makeUnion(cursor))
        case .typedefDecl: return makeTypedef(cursor).map(ObjCDeclaration.typedef)
        case .functionDecl: return makeFunction(cursor).map(ObjCDeclaration.function)
        case .varDecl: return makeVariable(cursor).map(ObjCDeclaration.variable)
        case .macroDefinition: return makeMacro(cursor).map(ObjCDeclaration.macro)
        case .inclusionDirective: return makeInclude(cursor).map(ObjCDeclaration.include)
        case .moduleImportDecl: return makeModuleImport(cursor).map(ObjCDeclaration.moduleImport)
        case .objcClassRef: return makeForwardDeclaration(cursor, kind: .class).map(ObjCDeclaration.forwardDeclaration)
        case .objcProtocolRef: return makeForwardDeclaration(cursor, kind: .protocol).map(ObjCDeclaration.forwardDeclaration)
        default: return nil
        }
    }

    private func makeClass(_ cursor: Cursor) -> ObjCClass? {
        guard !cursor.spelling.isEmpty else { return nil }
        var superclass: ObjCTypeReference?
        var protocols: [ObjCProtocolReference] = []
        var properties: [ObjCProperty] = []
        var methods: [ObjCMethod] = []
        var ivars: [ObjCIvar] = []
        var ivarAccess: ObjCIvar.AccessControl = .protected

        for child in cursor.children {
            switch child.kind {
            case .objcSuperClassRef: superclass = reference(child)
            case .objcProtocolRef: protocols.append(reference(child))
            case .objcPropertyDecl: properties.append(makeProperty(child))
            case .objcInstanceMethodDecl: methods.append(makeMethod(child, kind: .instance))
            case .objcClassMethodDecl: methods.append(makeMethod(child, kind: .class))
            case .objcIvarDecl: ivars.append(makeIvar(child, access: ivarAccess))
            case .cxxAccessSpecifier: ivarAccess = accessControl(from: child.displayName)
            default: break
            }
        }
        return ObjCClass(info: info(cursor), name: cursor.spelling, superclass: superclass, protocols: unique(protocols), properties: properties, methods: methods, ivars: ivars, genericParameters: genericParameters(cursor))
    }

    private func makeProtocol(_ cursor: Cursor) -> ObjCProtocol? {
        guard !cursor.spelling.isEmpty else { return nil }
        var inherited: [ObjCProtocolReference] = []
        var methods: [ObjCMethod] = []
        var properties: [ObjCProperty] = []
        for child in cursor.children {
            switch child.kind {
            case .objcProtocolRef: inherited.append(reference(child))
            case .objcInstanceMethodDecl: methods.append(makeMethod(child, kind: .instance))
            case .objcClassMethodDecl: methods.append(makeMethod(child, kind: .class))
            case .objcPropertyDecl: properties.append(makeProperty(child))
            default: break
            }
        }
        return ObjCProtocol(info: info(cursor), name: cursor.spelling, inheritedProtocols: unique(inherited), methods: methods, properties: properties)
    }

    private func makeCategory(_ cursor: Cursor) -> ObjCCategory? {
        var classReference: ObjCTypeReference?
        var protocols: [ObjCProtocolReference] = []
        var methods: [ObjCMethod] = []
        var properties: [ObjCProperty] = []
        for child in cursor.children {
            switch child.kind {
            case .objcClassRef: classReference = reference(child)
            case .objcProtocolRef: protocols.append(reference(child))
            case .objcInstanceMethodDecl: methods.append(makeMethod(child, kind: .instance))
            case .objcClassMethodDecl: methods.append(makeMethod(child, kind: .class))
            case .objcPropertyDecl: properties.append(makeProperty(child))
            default: break
            }
        }
        guard let classReference else { return nil }
        return ObjCCategory(info: info(cursor), name: emptyToNil(cursor.spelling), classReference: classReference, protocols: unique(protocols), properties: properties, methods: methods)
    }

    private func makeMethod(_ cursor: Cursor, kind: ObjCMethodKind) -> ObjCMethod {
        ObjCMethod(
            info: info(cursor),
            selector: cursor.spelling,
            kind: kind,
            returnType: type(cursor.resultType ?? cursor.type.result ?? cursor.type),
            returnQualifiers: declQualifiers(cursor.objcDeclQualifiersRawValue),
            parameters: cursor.arguments.map { ObjCParameter(info: info($0), name: emptyToNil($0.spelling), type: type($0.type), qualifiers: declQualifiers($0.objcDeclQualifiersRawValue)) },
            isVariadic: cursor.isVariadic,
            isOptional: cursor.isOptionalObjCDeclaration,
            family: methodFamily(cursor.spelling),
            overriddenMethods: cursor.overridden.map(declarationReference)
        )
    }

    private func makeProperty(_ cursor: Cursor) -> ObjCProperty {
        let attributes = propertyAttributes(cursor.objcPropertyAttributesRawValue)
        let getter = cursor.objcPropertyGetterName ?? cursor.spelling
        let setter = attributes.contains(.readonly) ? nil : (cursor.objcPropertySetterName ?? "set\(cursor.spelling.prefix(1).uppercased())\(cursor.spelling.dropFirst()):")
        return ObjCProperty(info: info(cursor), name: cursor.spelling, type: type(cursor.type), attributes: attributes, getter: getter, setter: setter, isClassProperty: attributes.contains(.classProperty), isOptional: cursor.isOptionalObjCDeclaration)
    }

    private func makeIvar(_ cursor: Cursor, access: ObjCIvar.AccessControl) -> ObjCIvar {
        ObjCIvar(info: info(cursor), name: cursor.spelling, type: type(cursor.type), accessControl: access, offset: cursor.fieldOffset)
    }

    private func makeEnum(_ cursor: Cursor) -> ObjCEnum {
        let cases = cursor.children.compactMap { child -> ObjCEnumCase? in
            guard child.kind == .enumConstantDecl else { return nil }
            let text = declarationText(child)
            return ObjCEnumCase(info: info(child), name: child.spelling, signedValue: child.enumSignedValue, unsignedValue: child.enumUnsignedValue, expression: valueExpression(in: text, separator: "="))
        }
        let text = declarationText(cursor)
        return ObjCEnum(info: info(cursor), name: emptyToNil(cursor.spelling), underlyingType: cursor.enumIntegerType.map { type($0) }, cases: cases, style: enumStyle(text))
    }

    private func makeStruct(_ cursor: Cursor) -> ObjCStruct {
        ObjCStruct(info: info(cursor), name: emptyToNil(cursor.spelling), fields: makeFields(cursor), size: cursor.type.size, alignment: cursor.type.alignment, isAnonymous: cursor.isAnonymousRecord)
    }

    private func makeUnion(_ cursor: Cursor) -> ObjCUnion {
        ObjCUnion(info: info(cursor), name: emptyToNil(cursor.spelling), fields: makeFields(cursor), size: cursor.type.size, alignment: cursor.type.alignment, isAnonymous: cursor.isAnonymousRecord)
    }

    private func makeFields(_ cursor: Cursor) -> [ObjCField] {
        cursor.children.compactMap { child in
            guard child.kind == .fieldDecl else { return nil }
            let text = declarationText(child)
            return ObjCField(info: info(child), name: emptyToNil(child.spelling), type: type(child.type), offset: child.fieldOffset, bitWidth: child.bitWidth, bitWidthExpression: child.isBitField ? valueExpression(in: text, separator: ":") : nil)
        }
    }

    private func makeTypedef(_ cursor: Cursor) -> ObjCTypedef? {
        guard !cursor.spelling.isEmpty else { return nil }
        let underlying = clang_getTypedefDeclUnderlyingType(cursor.rawValue)
        let clangType = cursor.wrapping(type: underlying)
        let declaration = clangType.declaration
        return ObjCTypedef(
            info: info(cursor),
            name: cursor.spelling,
            underlyingType: type(clangType),
            canonicalType: type(clangType.canonical),
            associatedDeclaration: declaration.map(declarationReference),
            style: typedefStyle(declarationText(cursor))
        )
    }

    private func makeFunction(_ cursor: Cursor) -> ObjCFunction? {
        guard !cursor.spelling.isEmpty else { return nil }
        return ObjCFunction(
            info: info(cursor),
            name: cursor.spelling,
            returnType: type(cursor.resultType ?? cursor.type.result ?? cursor.type),
            parameters: cursor.arguments.map { ObjCParameter(info: info($0), name: emptyToNil($0.spelling), type: type($0.type), qualifiers: declQualifiers($0.objcDeclQualifiersRawValue)) },
            isVariadic: cursor.isVariadic,
            isInline: cursor.isInlineFunction,
            storageClass: .init(rawValue: cursor.storageClassRawValue),
            callingConvention: callingConvention(cursor.type)
        )
    }

    private func makeVariable(_ cursor: Cursor) -> ObjCVariable? {
        guard !cursor.spelling.isEmpty else { return nil }
        return ObjCVariable(
            info: info(cursor),
            name: cursor.spelling,
            type: type(cursor.type),
            hasGlobalStorage: cursor.hasGlobalStorage,
            hasExternalStorage: cursor.hasExternalStorage,
            storageClass: .init(rawValue: cursor.storageClassRawValue),
            tlsKind: .init(rawValue: cursor.tlsKindRawValue),
            initializer: cursor.variableInitializer.map(declarationText)
        )
    }

    private func makeMacro(_ cursor: Cursor) -> ObjCMacro? {
        guard !cursor.spelling.isEmpty else { return nil }
        let tokenSpellings = cursor.extent.tokens.map(\.spelling)
        let parsed = macroParts(name: cursor.spelling, tokens: tokenSpellings, isFunctionLike: cursor.isFunctionLikeMacro)
        return ObjCMacro(info: info(cursor), name: cursor.spelling, definition: declarationText(cursor), isFunctionLike: cursor.isFunctionLikeMacro, isBuiltin: cursor.isBuiltinMacro, parameters: parsed.parameters, replacementTokens: parsed.replacement, isVariadic: parsed.isVariadic)
    }

    private func makeInclude(_ cursor: Cursor) -> ObjCInclude? {
        let text = declarationText(cursor).trimmingCharacters(in: .whitespacesAndNewlines)
        let isImport = text.hasPrefix("#import")
        let isAngled = text.contains("<") && text.contains(">")
        let spelling = includeSpelling(from: text) ?? cursor.spelling
        guard !spelling.isEmpty else { return nil }
        return ObjCInclude(info: info(cursor), spelling: spelling, resolvedURL: cursor.includedFile, isImport: isImport, isAngled: isAngled)
    }

    private func makeForwardDeclaration(_ cursor: Cursor, kind: ObjCForwardDeclaration.Kind) -> ObjCForwardDeclaration? {
        guard !cursor.spelling.isEmpty else { return nil }
        return ObjCForwardDeclaration(info: info(cursor), kind: kind, name: cursor.spelling)
    }

    private func makeModuleImport(_ cursor: Cursor) -> ObjCModuleImport? {
        let name = emptyToNil(cursor.spelling) ?? emptyToNil(cursor.displayName)
        guard let name else { return nil }
        return ObjCModuleImport(info: info(cursor), moduleName: name)
    }

    private func reference(_ cursor: Cursor) -> ObjCTypeReference {
        let target = cursor.referenced
        return ObjCTypeReference(name: cursor.spelling, usr: target?.usr ?? cursor.usr)
    }

    private func declarationReference(_ cursor: Cursor) -> ObjCDeclarationReference {
        ObjCDeclarationReference(name: emptyToNil(cursor.spelling), usr: cursor.usr)
    }

    private func type(_ clangType: ClangType, depth: Int = 0) -> ObjCType {
        guard depth < 32 else {
            return ObjCType(kind: .other, clangKindRawValue: clangType.kind.rawValue, spelling: clangType.spelling, canonicalSpelling: clangType.canonical.spelling)
        }
        let declaration = clangType.declaration
        let spelling = clangType.spelling
        return ObjCType(
            kind: typeKind(clangType.kind),
            clangKindRawValue: clangType.kind.rawValue,
            spelling: spelling,
            canonicalSpelling: clangType.canonical.spelling,
            nullability: nullability(clangType.nullability),
            ownership: ownership(spelling),
            isKindOf: spelling.contains("__kindof"),
            qualifiers: typeQualifiers(clangType),
            declarationUSR: declaration?.usr,
            declarationName: emptyToNil(declaration?.spelling ?? ""),
            pointeeType: clangType.pointee.map { type($0, depth: depth + 1) },
            elementType: (clangType.arrayElementType ?? clangType.elementType).map { type($0, depth: depth + 1) },
            resultType: clangType.result.map { type($0, depth: depth + 1) },
            parameterTypes: clangType.argumentTypes.map { type($0, depth: depth + 1) },
            typeArguments: clangType.objcTypeArguments.map { type($0, depth: depth + 1) },
            protocols: clangType.objcProtocolDeclarations.map(\.spelling),
            arraySize: clangType.arraySize,
            size: clangType.size,
            alignment: clangType.alignment,
            isVariadic: clangType.isVariadic,
            callingConvention: callingConvention(clangType)
        )
    }

    private func info(_ cursor: Cursor) -> ObjCDeclarationInfo {
        let normalized = normalizedDeclarationText(cursor)
        let source = sourceText(cursor) ?? normalized
        return ObjCDeclarationInfo(
            name: emptyToNil(cursor.spelling),
            usr: cursor.usr,
            sourceText: source,
            normalizedSourceText: normalized,
            headerText: containerHeaderText(cursor),
            location: ObjCSourceLocation(cursor.location),
            expansionLocation: ObjCSourceLocation(cursor.expansionLocation),
            extent: ObjCSourceRange(cursor.extent),
            availability: generalAvailability(cursor.availability.kind),
            platformAvailability: platformAvailability(cursor),
            attributes: cursor.children.filter(\.isAttribute).map { attribute($0) },
            documentation: documentation(cursor),
            isDefinition: cursor.isDefinition,
            canonical: referenceIfMeaningful(cursor.canonical, comparedTo: cursor),
            semanticParent: cursor.semanticParent.map(declarationReference),
            lexicalParent: cursor.lexicalParent.map(declarationReference),
            referenced: cursor.referenced.map(declarationReference),
            definition: cursor.definition.map(declarationReference),
            linkage: .init(rawValue: cursor.linkageRawValue),
            visibility: .init(rawValue: cursor.visibilityRawValue)
        )
    }

    private func attribute(_ cursor: Cursor) -> ObjCAttribute {
        ObjCAttribute(kind: .init(rawValue: cursor.kind.rawValue), kindSpelling: cursor.kindSpelling, spelling: cursor.spelling, sourceText: declarationText(cursor))
    }

    private func referenceIfMeaningful(_ candidate: Cursor, comparedTo cursor: Cursor) -> ObjCDeclarationReference? {
        let candidateUSR = candidate.usr
        guard candidateUSR != nil, candidateUSR != cursor.usr || candidate.spelling != cursor.spelling else { return nil }
        return declarationReference(candidate)
    }

    private func documentation(_ cursor: Cursor) -> ObjCDocumentation? {
        let value = ObjCDocumentation(raw: cursor.rawComment, brief: cursor.briefComment)
        return value.isEmpty ? nil : value
    }

    private func platformAvailability(_ cursor: Cursor) -> [ObjCAvailability] {
        var alwaysDeprecated: Int32 = 0
        var deprecatedMessage = CXString()
        var alwaysUnavailable: Int32 = 0
        var unavailableMessage = CXString()
        let count = clang_getCursorPlatformAvailability(cursor.rawValue, &alwaysDeprecated, &deprecatedMessage, &alwaysUnavailable, &unavailableMessage, nil, 0)
        clang_disposeString(deprecatedMessage)
        clang_disposeString(unavailableMessage)
        guard count > 0 else { return [] }
        deprecatedMessage = CXString(); unavailableMessage = CXString()
        var values = Array(repeating: CXPlatformAvailability(), count: Int(count))
        let actual = values.withUnsafeMutableBufferPointer { buffer in
            clang_getCursorPlatformAvailability(cursor.rawValue, &alwaysDeprecated, &deprecatedMessage, &alwaysUnavailable, &unavailableMessage, buffer.baseAddress, Int32(buffer.count))
        }
        clang_disposeString(deprecatedMessage); clang_disposeString(unavailableMessage)
        return values.prefix(Int(actual)).map { value in
            defer { var copy = value; clang_disposeCXPlatformAvailability(&copy) }
            return ObjCAvailability(platform: cxString(value.Platform), introduced: version(value.Introduced), deprecated: version(value.Deprecated), obsoleted: version(value.Obsoleted), isUnavailable: value.Unavailable != 0, message: emptyToNil(cxString(value.Message)))
        }
    }

    private func cxString(_ value: CXString) -> String {
        guard let pointer = clang_getCString(value) else { return "" }
        return String(cString: pointer)
    }

    private func version(_ value: CXVersion) -> ObjCAvailability.Version? {
        guard value.Major >= 0 else { return nil }
        return .init(major: Int(value.Major), minor: max(0, Int(value.Minor)), patch: max(0, Int(value.Subminor)))
    }

    private func sourceText(_ cursor: Cursor) -> String? {
        if cursor.kind == .objcClassRef || cursor.kind == .objcProtocolRef {
            if let text = forwardDeclarationSourceText(cursor) { return text }
        }

        let trailingDelimiter: UInt8?
        switch cursor.kind {
        case .objcPropertyDecl, .objcInstanceMethodDecl, .objcClassMethodDecl, .objcIvarDecl,
             .fieldDecl, .typedefDecl, .functionDecl, .varDecl:
            trailingDelimiter = UInt8(ascii: ";")
        case .enumConstantDecl:
            trailingDelimiter = UInt8(ascii: ",")
        default:
            trailingDelimiter = nil
        }
        return exactSourceText(cursor.extent, extendingThrough: trailingDelimiter)
    }

    private func exactDeclarationText(_ cursor: Cursor) -> String? {
        sourceText(cursor)
    }

    private func declarationText(_ cursor: Cursor) -> String {
        sourceText(cursor) ?? normalizedDeclarationText(cursor)
    }

    private func exactSourceText(_ range: Clang.SourceRange, extendingThrough delimiter: UInt8? = nil) -> String? {
        let start = range.start
        let end = range.end
        guard let file = start.file, file == end.file, end.offset >= start.offset,
              let data = sourceCache.data(for: file) else { return nil }

        let lower = Int(start.offset)
        var upper = Int(end.offset)
        guard lower >= 0, upper >= lower, upper <= data.count else { return nil }

        if let delimiter {
            upper = extendedEndOffset(in: data, from: upper, through: delimiter)
        }

        return String(data: data[lower..<upper], encoding: .utf8)
    }

    private func extendedEndOffset(in data: Data, from originalEnd: Int, through delimiter: UInt8) -> Int {
        var index = originalEnd
        while index < data.count {
            let byte = data[index]
            if byte == delimiter { return index + 1 }
            if byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") || byte == UInt8(ascii: "\r") || byte == UInt8(ascii: "\n") {
                index += 1
                continue
            }
            break
        }
        return originalEnd
    }

    private func forwardDeclarationSourceText(_ cursor: Cursor) -> String? {
        guard let file = cursor.location.file, let data = sourceCache.data(for: file) else { return nil }
        let offset = Int(cursor.location.offset)
        guard offset >= 0, offset <= data.count else { return nil }

        var lower = offset
        while lower > 0 && data[lower - 1] != UInt8(ascii: "\n") && data[lower - 1] != UInt8(ascii: "\r") {
            lower -= 1
        }
        var upper = offset
        while upper < data.count && data[upper] != UInt8(ascii: ";") && data[upper] != UInt8(ascii: "\n") && data[upper] != UInt8(ascii: "\r") {
            upper += 1
        }
        if upper < data.count && data[upper] == UInt8(ascii: ";") { upper += 1 }
        guard let line = String(data: data[lower..<upper], encoding: .utf8) else { return nil }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let expected = cursor.kind == .objcClassRef ? "@class" : "@protocol"
        return trimmed.hasPrefix(expected) ? trimmed : nil
    }

    private func containerHeaderText(_ cursor: Cursor) -> String? {
        guard cursor.kind == .objcInterfaceDecl || cursor.kind == .objcProtocolDecl || cursor.kind == .objcCategoryDecl,
              let file = cursor.extent.start.file,
              let data = sourceCache.data(for: file) else { return nil }

        let startOffset = Int(cursor.extent.start.offset)
        guard startOffset >= 0, startOffset <= data.count else { return nil }

        let memberKinds: Set<Cursor.Kind> = [
            .objcPropertyDecl, .objcInstanceMethodDecl, .objcClassMethodDecl, .objcIvarDecl
        ]
        let firstMemberOffset = cursor.children
            .filter { memberKinds.contains($0.kind) && $0.location.file == file }
            .map { Int($0.extent.start.offset) }
            .filter { $0 >= startOffset }
            .min()

        let fullText = sourceText(cursor) ?? ""
        var header: String
        if let firstMemberOffset, firstMemberOffset <= data.count {
            header = String(data: data[startOffset..<firstMemberOffset], encoding: .utf8) ?? ""
        } else if let endRange = fullText.range(of: "@end") {
            header = String(fullText[..<endRange.lowerBound])
        } else {
            header = fullText
        }

        header = header.trimmingCharacters(in: .whitespacesAndNewlines)
        for marker in ["@required", "@optional"] {
            if header.hasSuffix(marker) {
                header.removeLast(marker.count)
                header = header.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if header.last == "{" {
            header.removeLast()
            header = header.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return header.isEmpty ? nil : header
    }

    private func normalizedDeclarationText(_ cursor: Cursor) -> String {
        cursor.extent.tokens.map(\.spelling).joined(separator: " ")
            .replacingOccurrences(of: " ;", with: ";")
            .replacingOccurrences(of: " ,", with: ",")
            .replacingOccurrences(of: " )", with: ")")
            .replacingOccurrences(of: "( ", with: "(")
    }

    private func macroParts(name: String, tokens: [String], isFunctionLike: Bool) -> (parameters: [String], replacement: [String], isVariadic: Bool) {
        guard let nameIndex = tokens.firstIndex(of: name) else { return ([], tokens, tokens.contains("...")) }
        guard isFunctionLike, nameIndex + 1 < tokens.count, tokens[nameIndex + 1] == "(" else {
            return ([], Array(tokens.dropFirst(nameIndex + 1)), false)
        }
        var depth = 0, endIndex: Int?
        for index in (nameIndex + 1)..<tokens.count {
            if tokens[index] == "(" { depth += 1 }
            if tokens[index] == ")" { depth -= 1; if depth == 0 { endIndex = index; break } }
        }
        guard let endIndex else { return ([], [], tokens.contains("...")) }
        let parameterTokens = Array(tokens[(nameIndex + 2)..<endIndex])
        let parameters = parameterTokens.split(separator: ",").map { $0.joined().trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return (parameters, Array(tokens.dropFirst(endIndex + 1)), parameterTokens.contains("..."))
    }

    private func includeSpelling(from text: String) -> String? {
        if let a = text.firstIndex(of: "<"), let b = text[a...].firstIndex(of: ">") { return String(text[text.index(after: a)..<b]) }
        if let a = text.firstIndex(of: "\""), let b = text[text.index(after: a)...].firstIndex(of: "\"") { return String(text[text.index(after: a)..<b]) }
        return nil
    }

    private func valueExpression(in text: String, separator: Character) -> String? {
        guard let index = text.firstIndex(of: separator) else { return nil }
        var value = text[text.index(after: index)...].trimmingCharacters(in: .whitespacesAndNewlines)
        while value.last == "," || value.last == ";" { value.removeLast() }
        return value.isEmpty ? nil : value
    }

    private func enumStyle(_ text: String) -> ObjCEnum.Style {
        if text.contains("NS_OPTIONS") || text.contains("CF_OPTIONS") { return .options }
        if text.contains("NS_ERROR_ENUM") { return .error }
        if text.contains("NS_ENUM") || text.contains("CF_ENUM") { return .enum }
        return .plain
    }

    private func typedefStyle(_ text: String) -> ObjCTypedef.Style {
        if text.contains("NS_TYPED_EXTENSIBLE_ENUM") { return .typedExtensibleEnum }
        if text.contains("NS_TYPED_ENUM") { return .typedEnum }
        if text.contains("NS_EXTENSIBLE_STRING_ENUM") { return .extensibleStringEnum }
        if text.contains("NS_ERROR_ENUM") { return .errorEnum }
        if text.contains("NS_OPTIONS") || text.contains("CF_OPTIONS") { return .options }
        if text.contains("NS_ENUM") || text.contains("CF_ENUM") { return .enum }
        return .plain
    }

    private func ownership(_ spelling: String) -> ObjCType.Ownership? {
        if spelling.contains("__weak") { return .weak }
        if spelling.contains("__autoreleasing") { return .autoreleasing }
        if spelling.contains("__unsafe_unretained") { return .unsafeUnretained }
        if spelling.contains("__strong") { return .strong }
        return nil
    }

    private func genericParameters(_ cursor: Cursor) -> [ObjCGenericParameter] {
        let text = declarationText(cursor)
        guard let interfaceRange = text.range(of: "@interface") else { return [] }
        let remainder = text[interfaceRange.upperBound...]
        guard let nameRange = remainder.range(of: cursor.spelling) else { return [] }
        let afterName = remainder[nameRange.upperBound...].drop(while: { $0.isWhitespace })
        guard afterName.first == "<" else { return [] }
        let open = afterName.startIndex
        guard let close = afterName[open...].firstIndex(of: ">") else { return [] }
        return remainder[remainder.index(after: open)..<close].split(separator: ",").compactMap { raw in
            var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let variance: ObjCGenericParameter.Variance
            if value.hasPrefix("__covariant") { variance = .covariant; value.removeFirst("__covariant".count) }
            else if value.hasPrefix("__contravariant") { variance = .contravariant; value.removeFirst("__contravariant".count) }
            else { variance = .invariant }
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return nil }
            if let colon = value.firstIndex(of: ":") {
                let name = value[..<colon].trimmingCharacters(in: .whitespaces)
                let bound = value[value.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                return ObjCGenericParameter(name: name, variance: variance, bound: bound.isEmpty ? nil : bound)
            }
            return ObjCGenericParameter(name: value, variance: variance)
        }
    }

    private func methodFamily(_ selector: String) -> ObjCMethod.Family {
        let first = selector.split(separator: ":", maxSplits: 1).first.map(String.init) ?? selector
        func familyPrefix(_ prefix: String) -> Bool {
            guard first.hasPrefix(prefix) else { return false }
            let rest = first.dropFirst(prefix.count)
            guard let c = rest.first else { return true }
            return !c.isLowercase
        }
        if familyPrefix("alloc") { return .alloc }
        if familyPrefix("init") { return .initFamily }
        if familyPrefix("mutableCopy") { return .mutableCopy }
        if familyPrefix("copy") { return .copy }
        if familyPrefix("new") { return .new }
        return .none
    }

    private func callingConvention(_ value: ClangType) -> ObjCCallingConvention? {
        guard value.kind == .functionNoPrototype || value.kind == .functionPrototype || value.kind == .blockPointer else { return nil }
        return .init(rawValue: value.callingConventionRawValue)
    }

    private func unique<T: Hashable>(_ values: [T]) -> [T] { var seen = Set<T>(); return values.filter { seen.insert($0).inserted } }
    private func emptyToNil(_ value: String) -> String? { value.isEmpty ? nil : value }

    private func accessControl(from value: String) -> ObjCIvar.AccessControl {
        switch value {
        case "private", "@private": return .private
        case "public", "@public": return .public
        case "package", "@package": return .package
        case "protected", "@protected": return .protected
        default: return .none
        }
    }

    private func propertyAttributes(_ raw: UInt32) -> ObjCPropertyAttributes {
        var result: ObjCPropertyAttributes = []
        if raw & 0x001 != 0 { result.insert(.readonly) }; if raw & 0x002 != 0 { result.insert(.getter) }; if raw & 0x004 != 0 { result.insert(.assign) }
        if raw & 0x008 != 0 { result.insert(.readwrite) }; if raw & 0x010 != 0 { result.insert(.retain) }; if raw & 0x020 != 0 { result.insert(.copy) }
        if raw & 0x040 != 0 { result.insert(.nonatomic) }; if raw & 0x080 != 0 { result.insert(.setter) }; if raw & 0x100 != 0 { result.insert(.atomic) }
        if raw & 0x200 != 0 { result.insert(.weak) }; if raw & 0x400 != 0 { result.insert(.strong) }; if raw & 0x800 != 0 { result.insert(.unsafeUnretained) }
        if raw & 0x1000 != 0 { result.insert(.classProperty) }
        return result
    }

    private func declQualifiers(_ raw: UInt32) -> ObjCDeclQualifiers {
        var result: ObjCDeclQualifiers = []
        if raw & 0x01 != 0 { result.insert(.in) }; if raw & 0x02 != 0 { result.insert(.inoutQualifier) }; if raw & 0x04 != 0 { result.insert(.out) }
        if raw & 0x08 != 0 { result.insert(.bycopy) }; if raw & 0x10 != 0 { result.insert(.byref) }; if raw & 0x20 != 0 { result.insert(.oneway) }
        return result
    }

    private func typeQualifiers(_ value: ClangType) -> ObjCType.Qualifiers {
        var result: ObjCType.Qualifiers = []
        if value.isConstQualified { result.insert(.const) }; if value.isVolatileQualified { result.insert(.volatile) }; if value.isRestrictQualified { result.insert(.restrict) }
        return result
    }

    private func generalAvailability(_ kind: Availability.Kind) -> ObjCGeneralAvailability {
        switch kind { case .available: return .available; case .deprecated: return .deprecated; case .notAvailable: return .unavailable; case .notAccessible: return .inaccessible; case .unknown: return .unknown }
    }

    private func nullability(_ kind: ClangType.Nullability) -> ObjCType.Nullability? {
        switch kind { case .nonnull: return .nonnull; case .nullable: return .nullable; case .unspecified: return .unspecified; case .nullableResult: return .nullableResult; case .invalid: return nil; default: return .invalid }
    }

    private func typeKind(_ kind: ClangType.Kind) -> ObjCType.Kind {
        switch kind {
        case .invalid: return .invalid; case .unexposed: return .unexposed; case .void: return .void; case .bool: return .bool
        case .charS, .charU: return .char; case .sChar: return .signedChar; case .uChar: return .unsignedChar; case .short: return .short; case .uShort: return .unsignedShort
        case .int: return .int; case .uInt: return .unsignedInt; case .long: return .long; case .uLong: return .unsignedLong; case .longLong: return .longLong; case .uLongLong: return .unsignedLongLong
        case .int128: return .int128; case .uInt128: return .unsignedInt128; case .float: return .float; case .double: return .double; case .longDouble: return .longDouble; case .half: return .half; case .float128: return .float128
        case .objcId: return .objcId; case .objcClass: return .objcClass; case .objcSel: return .objcSelector; case .objcInterface: return .objcInterface; case .objcObject: return .objcObject; case .objcObjectPointer: return .objcObjectPointer
        case .pointer: return .pointer; case .blockPointer: return .blockPointer; case .functionNoPrototype: return .functionNoPrototype; case .functionPrototype: return .functionPrototype
        case .constantArray: return .constantArray; case .incompleteArray: return .incompleteArray; case .variableArray: return .variableArray; case .dependentSizedArray: return .dependentSizedArray
        case .vector: return .vector; case .extendedVector: return .extendedVector; case .record: return .record; case .enumeration: return .enumeration; case .typedef: return .typedef
        case .elaborated: return .elaborated; case .attributed: return .attributed; case .atomic: return .atomic; case .complex: return .complex
        default: return .other
        }
    }
}

private final class SourceFileCache {
    private var values: [URL: Data] = [:]
    private let lock = NSLock()

    func data(for url: URL) -> Data? {
        let key = url.standardizedFileURL
        lock.lock()
        defer { lock.unlock() }
        if let value = values[key] { return value }
        guard let value = try? Data(contentsOf: key) else { return nil }
        values[key] = value
        return value
    }

    func string(for url: URL) -> String? {
        guard let data = data(for: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
