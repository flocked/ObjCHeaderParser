import Foundation

public struct ObjCAvailability: Codable, Hashable, Sendable {
    public let platform: String
    public let introduced: Version?
    public let deprecated: Version?
    public let obsoleted: Version?
    public let isUnavailable: Bool
    public let message: String?

    public init(
        platform: String,
        introduced: Version? = nil,
        deprecated: Version? = nil,
        obsoleted: Version? = nil,
        isUnavailable: Bool = false,
        message: String? = nil
    ) {
        self.platform = platform
        self.introduced = introduced
        self.deprecated = deprecated
        self.obsoleted = obsoleted
        self.isUnavailable = isUnavailable
        self.message = message
    }

    public struct Version: Codable, Hashable, Sendable, CustomStringConvertible {
        public let major: Int
        public let minor: Int
        public let patch: Int

        public init(major: Int, minor: Int = 0, patch: Int = 0) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }

        public var description: String {
            patch != 0 ? "\(major).\(minor).\(patch)" : "\(major).\(minor)"
        }
    }
}

public enum ObjCGeneralAvailability: String, Codable, Hashable, Sendable {
    case available
    case deprecated
    case unavailable
    case inaccessible
    case unknown
}
