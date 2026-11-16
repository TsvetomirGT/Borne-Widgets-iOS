import Foundation
import os

/// Shared storage between the app and the widget extension.
///
/// The group identifier comes from the `BorneAppGroup` Info.plist key, which
/// XcodeGen fills from `BUNDLE_PREFIX`. Sideloading tools (AltStore, SideStore)
/// re-sign the app with the user's own team, which renames the group; they
/// record the new identifier under `ALTAppGroups`, so that wins when present.
/// When no group is configured or the container is unavailable (unit tests,
/// misconfigured signing) we fall back to local storage so nothing crashes;
/// app and widgets just won't share data.
public enum AppGroup {
    private static let log = Logger(subsystem: "BorneWidgets", category: "AppGroup")

    public static var identifier: String? {
        identifier(in: Bundle.main.infoDictionary ?? [:])
    }

    /// Picks the App Group from an Info.plist dictionary. Pure, for tests.
    static func identifier(in info: [String: Any]) -> String? {
        if let rewritten = (info["ALTAppGroups"] as? [String])?.first(where: { !$0.isEmpty }) {
            return rewritten
        }
        guard let id = info["BorneAppGroup"] as? String, !id.isEmpty else { return nil }
        return id
    }

    public static var isShared: Bool { sharedContainerURL != nil }

    private static var sharedContainerURL: URL? {
        guard let identifier else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    public static var containerURL: URL {
        if let url = sharedContainerURL { return url }
        log.warning("App Group container unavailable; using local caches directory")
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    public static var defaults: UserDefaults {
        if let identifier, isShared, let shared = UserDefaults(suiteName: identifier) {
            return shared
        }
        return .standard
    }
}
