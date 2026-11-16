import Foundation
import Testing
@testable import BorneCore

@Test func appGroupFallsBackWhenNotConfigured() {
    // The test bundle has no `BorneAppGroup` key, so we must fall back
    // to a usable local container rather than crash.
    #expect(AppGroup.identifier == nil)
    #expect(FileManager.default.fileExists(atPath: AppGroup.containerURL.path))
    #expect(AppGroup.defaults === UserDefaults.standard)
}
