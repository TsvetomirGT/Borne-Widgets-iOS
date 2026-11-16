import Foundation

/// Runs at most one operation at a time; callers that arrive while one is
/// in flight await its result instead of starting their own.
public actor SingleFlight<Value: Sendable> {
    private var inFlight: Task<Value, Error>?

    public init() {}

    public func run(_ operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        if let inFlight { return try await inFlight.value }
        let task = Task { try await operation() }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}

extension Error {
    /// True for Swift task cancellation and for URLSession's cancelled requests.
    public var isCancellation: Bool {
        if self is CancellationError { return true }
        if let url = self as? URLError, url.code == .cancelled { return true }
        return false
    }
}
