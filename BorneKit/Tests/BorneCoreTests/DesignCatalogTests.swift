import Testing
@testable import BorneCore

@Test func allCards() {
    #expect(DesignCatalog.cards().count == 12)
}

@Test func filterBySize() {
    #expect(DesignCatalog.cards(size: .large).count == 3)
}

@Test func combinedFilters() {
    #expect(DesignCatalog.cards(size: .small, category: .weather).map(\.id) == ["editorial.weather.small"])
}

@Test func styleFilter() {
    #expect(DesignCatalog.cards(style: .editorial).count == 12)
}

@Test func querySearchIsTrimmedAndCaseInsensitive() {
    #expect(DesignCatalog.cards(query: "  MOON ").map(\.id) == ["editorial.sunmoon.small"])
    #expect(DesignCatalog.cards(query: "zzz").isEmpty)
}

@Test func queryMatchesCategoryTitle() {
    #expect(DesignCatalog.cards(query: "clock").count == 3)
}

@Test func orderIsCatalogThenSize() {
    #expect(DesignCatalog.cards(category: .clock).map(\.size) == [.small, .medium, .large])
}

@Test func designIdsAreUniqueAndStable() {
    let ids = DesignCatalog.all.map(\.id)
    #expect(ids == ["editorial.weather", "editorial.clock", "editorial.sunmoon", "editorial.calendar"])
}

@Test func extraLargeIsWeatherAndCalendar() {
    #expect(DesignCatalog.cards(size: .extraLarge).map(\.id) == ["editorial.weather.extraLarge", "editorial.calendar.extraLarge"])
    #expect(WidgetSize.extraLarge.title == "Extra Large")
}

@Test func extraLargeIsPortrait() {
    let s = WidgetSize.extraLarge.previewSize
    #expect(s.height > s.width)
    #expect(s.height > WidgetSize.large.previewSize.height * 1.5)
}

@Test func calendarCategoryHasFourSizes() {
    #expect(WidgetCategory.calendar.title == "Calendar")
    #expect(DesignCatalog.cards(category: .calendar).count == 4)
    #expect(DesignCatalog.design(id: "editorial.calendar")?.name == "Editorial Calendar")
}
