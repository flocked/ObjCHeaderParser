import Foundation
import Clang

public struct ObjCParser: Sendable {
    public struct Configuration: Sendable {
        public enum DeclarationScope: Hashable, Sendable {
            case mainFileOnly
            case allIncludedHeaders
        }

        public var sdk: URL?
        public var target: String?
        public var includePaths: [URL]
        public var frameworkPaths: [URL]
        public var defines: [String: String?]
        public var additionalArguments: [String]
        public var skipFunctionBodies: Bool
        public var declarationScope: DeclarationScope
        public var includeMacros: Bool
        public var includeImports: Bool

        public init(
            sdk: URL? = nil,
            target: String? = nil,
            includePaths: [URL] = [],
            frameworkPaths: [URL] = [],
            defines: [String: String?] = [:],
            additionalArguments: [String] = [],
            skipFunctionBodies: Bool = true,
            declarationScope: DeclarationScope = .mainFileOnly,
            includeMacros: Bool = false,
            includeImports: Bool = true
        ) {
            self.sdk = sdk
            self.target = target
            self.includePaths = includePaths
            self.frameworkPaths = frameworkPaths
            self.defines = defines
            self.additionalArguments = additionalArguments
            self.skipFunctionBodies = skipFunctionBodies
            self.declarationScope = declarationScope
            self.includeMacros = includeMacros
            self.includeImports = includeImports
        }

        public var clangArguments: [String] {
            var result = ["-x", "objective-c"]
            if let sdk { result += ["-isysroot", sdk.path] }
            if let target { result += ["-target", target] }
            result += includePaths.flatMap { ["-I", $0.path] }
            result += frameworkPaths.flatMap { ["-F", $0.path] }
            for (name, value) in defines.sorted(by: { $0.key < $1.key }) {
                result.append(value.map { "-D\(name)=\($0)" } ?? "-D\(name)")
            }
            result += additionalArguments
            return result
        }
    }

    public let configuration: Configuration

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    public func parse(_ url: URL) throws -> ObjCHeader {
        try parseResult(url).header
    }

    public func parseResult(_ url: URL) throws -> ObjCParseResult {
        let index = ClangIndex()
        var options: TranslationUnit.ParseOptions = configuration.skipFunctionBodies ? [.skipFunctionBodies, .keepGoing] : [.keepGoing]
        if configuration.includeMacros || configuration.includeImports {
            options.insert(.detailedPreprocessingRecord)
        }
        let unit = try index.parse(file: url, arguments: configuration.clangArguments, options: options)
        let header = ObjCExtractor().extract(
            from: unit,
            sourceURL: url,
            includeIncludedHeaders: configuration.declarationScope == .allIncludedHeaders,
            parseContext: .init(sdk: configuration.sdk, target: configuration.target, clangArguments: configuration.clangArguments)
        )
        return ObjCParseResult(header: header, diagnostics: unit.diagnostics.map(ObjCDiagnostic.init))
    }
}
