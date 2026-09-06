import Foundation

public enum ClangError: Error, CustomStringConvertible {
    case parseFailed(code: Int32)

    public var description: String {
        switch self {
        case .parseFailed(let code):
            return "libclang failed to parse the translation unit (error code: \(code))."
        }
    }
}
