import Foundation

public struct ObjCDocumentation: Codable, Hashable, Sendable {
    public let raw: String?
    public let brief: String?

    public init(raw: String? = nil, brief: String? = nil) {
        self.raw = raw
        self.brief = brief
    }

    public var isEmpty: Bool {
        (raw?.isEmpty ?? true) && (brief?.isEmpty ?? true)
    }
}
