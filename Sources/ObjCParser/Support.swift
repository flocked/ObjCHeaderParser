import Foundation

public struct Indirect<Value: Codable & Hashable & Sendable>: Codable, Hashable, @unchecked Sendable {
    private final class Storage: @unchecked Sendable {
        let value: Value
        init(_ value: Value) { self.value = value }
    }

    private let storage: Storage

    public init(_ value: Value) {
        storage = Storage(value)
    }

    public var value: Value { storage.value }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public init(from decoder: Decoder) throws {
        self.init(try Value(from: decoder))
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
