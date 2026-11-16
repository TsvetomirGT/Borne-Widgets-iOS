import Foundation
import os

/// Shared storage between the app and the widget extension.
///
/// The group identifier comes from the `BorneAppGroup` Info.plist key, which
/// XcodeGen fills from `BUNDLE_PREFIX`. When it is missing or the container is
/// unavailable (unit tests, misconfigured signing) we fall back to local
/// storage so nothing crashes; app and widgets just won't share data.
public enum AppGroup {
    private static let log = Logger(subsystem: "BorneWidgets", category: "AppGroup")

    public static var identifier: String? {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "BorneAppGroup") as? String,
              !id.isEmpty else { return nil }
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
