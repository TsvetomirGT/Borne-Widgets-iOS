import BorneCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showingCitySearch = false
    @State private var showingClockSearch = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section {
                    Picker("Location", selection: $model.locationMode) {
                        Text("Current location").tag(LocationMode.current)
                        Text("Chosen city").tag(LocationMode.manual)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    if model.locationMode == .current {
                        LabeledContent("Using", value: model.currentLocation?.name ?? "Not set")
                        Button {
                            Task { await model.useCurrentLocation() }
                        } label: {
                            Label("Update current location", systemImage: "location")
                        }
                    } else {
                        LabeledContent("City", value: model.manualLocation?.name ?? "Not set")
                    }
                    Button {
                        showingCitySearch = true
                    } label: {
                        Label("Search for a city", systemImage: "magnifyingglass")
                    }
                } header: {
                    Text("Weather location")
                } footer: {
                    if let error = model.locationError {
                        Text(error).foregroundStyle(.orange)
                    } else if model.isLocationDenied && model.locationMode == .current {
                        Text("Location access is off. Search for a city to use instead.")
                    }
                }

                Section("Units") {
                    Picker("Temperature", selection: $model.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Picker("Wind", selection: $model.windUnit) {
                        ForEach(WindUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                }

                Section {
                    Toggle("24-hour time", isOn: $model.uses24HourClock)
                    ForEach(model.worldClocks) { clock in
                        LabeledContent(clock.name, value: clock.timeZone.abbreviation() ?? clock.timeZoneID)
                    }
                    .onDelete { model.worldClocks.remove(atOffsets: $0) }
                    .onMove { model.worldClocks.move(fromOffsets: $0, toOffset: $1) }
                    if model.worldClocks.count < SettingsStore.maxWorldClocks {
                        Button {
                            showingClockSearch = true
                        } label: {
                            Label("Add world clock", systemImage: "plus")
                        }
                    }
                } header: {
                    Text("Clock")
                } footer: {
                    Text("Up to \(SettingsStore.maxWorldClocks) world clocks appear on the large Clock widget.")
                }

                Section {
                    CalendarAccessButton()
                } header: {
                    Text("Calendar")
                } footer: {
                    Text("Calendar widgets show events from every calendar on this iPhone. Events are read on the device only.")
                }

                Section {
                    Button {
                        Task { await model.refresh(force: true) }
                    } label: {
                        HStack {
                            Text("Refresh weather now")
                            Spacer()
                            if model.isRefreshing { ProgressView() }
                        }
                    }
                    .disabled(model.isRefreshing)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com")!)
                        Text("Borne \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .toolbar { EditButton() }
            .sheet(isPresented: $showingCitySearch) {
                CitySearchView(title: "Choose a city") { model.chooseCity($0) }
            }
            .sheet(isPresented: $showingClockSearch) {
                CitySearchView(title: "Add world clock") { city in
                    model.worldClocks.append(WorldClock(name: city.name, timeZoneID: city.timeZoneID))
                }
            }
        }
    }
}
