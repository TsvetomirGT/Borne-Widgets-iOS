import Foundation

/// When "Current location" should be looked up again.
public enum LocationRefreshPolicy {
    public static let maxAge: TimeInterval = 60 * 60

    public static func needsRefresh(resolvedAt: Date?, now: Date) -> Bool {
        guard let resolvedAt else { return true }
        return now.timeIntervalSince(resolvedAt) > maxAge
    }
}
