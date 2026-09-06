import CClang

public final class Diagnostic: @unchecked Sendable {
    public enum Severity: UInt32, Hashable, Sendable {
        case ignored = 0
        case note = 1
        case warning = 2
        case error = 3
        case fatal = 4
        case unknown = 255

        package init(rawClangValue: UInt32) {
            self = Self(rawValue: rawClangValue) ?? .unknown
        }
    }

    package let rawValue: CXDiagnostic

    package init(rawValue: CXDiagnostic) {
        self.rawValue = rawValue
    }

    deinit {
        clang_disposeDiagnostic(rawValue)
    }

    public var severity: Severity {
        Severity(rawClangValue: CClang_diagnosticSeverity(rawValue))
    }

    public var spelling: String {
        clang_getDiagnosticSpelling(rawValue).takeString()
    }

    public var formatted: String {
        clang_formatDiagnostic(rawValue, clang_defaultDiagnosticDisplayOptions()).takeString()
    }

    public var location: SourceLocation {
        SourceLocation(clang_getDiagnosticLocation(rawValue))
    }
}
