import Foundation
import Clang

public struct ObjCDiagnostic: Codable, Hashable, Sendable {
    public enum Severity: String, Codable, Hashable, Sendable {
        case ignored, note, warning, error, fatal, unknown
    }

    public let severity: Severity
    public let spelling: String
    public let formatted: String
    public let location: ObjCSourceLocation

    init(_ diagnostic: Clang.Diagnostic) {
        switch diagnostic.severity {
        case .ignored: severity = .ignored
        case .note: severity = .note
        case .warning: severity = .warning
        case .error: severity = .error
        case .fatal: severity = .fatal
        default: severity = .unknown
        }
        spelling = diagnostic.spelling
        formatted = diagnostic.formatted
        location = ObjCSourceLocation(diagnostic.location)
    }
}

public struct ObjCParseResult: Codable, Hashable, Sendable {
    public let header: ObjCHeader
    public let diagnostics: [ObjCDiagnostic]

    public init(header: ObjCHeader, diagnostics: [ObjCDiagnostic]) {
        self.header = header
        self.diagnostics = diagnostics
    }

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error || $0.severity == .fatal }
    }
}
