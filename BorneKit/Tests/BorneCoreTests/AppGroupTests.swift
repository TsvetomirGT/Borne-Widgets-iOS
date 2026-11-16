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

@Test func appGroupReadsBuildSettingKey() {
    let info: [String: Any] = ["BorneAppGroup": "group.dev.borne.bornewidgets"]
    #expect(AppGroup.identifier(in: info) == "group.dev.borne.bornewidgets")
}

@Test func appGroupPrefersGroupRewrittenBySideloader() {
    // AltStore / SideStore re-sign with the user's team, rename the group and
    // record the real identifier under `ALTAppGroups`.
    let info: [String: Any] = [
        "BorneAppGroup": "group.dev.borne.bornewidgets",
        "ALTAppGroups": ["group.dev.borne.bornewidgets.ABCDE12345"],
    ]
    #expect(AppGroup.identifier(in: info) == "group.dev.borne.bornewidgets.ABCDE12345")
}

@Test func appGroupIgnoresEmptyValues() {
    #expect(AppGroup.identifier(in: ["BorneAppGroup": ""]) == nil)
    #expect(AppGroup.identifier(in: ["ALTAppGroups": [String](), "BorneAppGroup": "g"]) == "g")
    #expect(AppGroup.identifier(in: [:]) == nil)
}
