import BorneCore
import CoreLocation
import MapKit

/// One-shot "where am I" with a friendly place name.
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum LocationError: LocalizedError {
        case denied, unavailable
        var errorDescription: String? {
            switch self {
            case .denied: "Location access is off. You can search for a city instead."
            case .unavailable: "Couldn't determine your location right now."
            }
        }
    }

    private let manager = CLLocationManager()
    private let flight = SingleFlight<SavedLocation>()
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var isDenied: Bool {
        let s = manager.authorizationStatus
        return s == .denied || s == .restricted
    }

    /// Overlapping callers share one lookup, so continuations are never overwritten.
    func requestCurrentLocation() async throws -> SavedLocation {
        try await flight.run { @MainActor in try await self.lookUp() }
    }

    private func lookUp() async throws -> SavedLocation {
        if manager.authorizationStatus == .notDetermined {
            _ = await withCheckedContinuation { c in
                authContinuation = c
                manager.requestWhenInUseAuthorization()
            }
        }
        guard !isDenied else { throw LocationError.denied }

        let location = try await withCheckedThrowingContinuation { c in
            locationContinuation = c
            manager.requestLocation()
        }
        return await Self.describe(location)
    }

    /// Reverse-geocodes to a city name and time zone (MapKit; CLGeocoder is deprecated).
    static func describe(_ location: CLLocation) async -> SavedLocation {
        var name = "Current location"
        var zone = TimeZone.current
        if let request = MKReverseGeocodingRequest(location: location),
           let item = try? await request.mapItems.first {
            name = item.addressRepresentations?.cityName ?? item.name ?? name
            zone = item.timeZone ?? zone
        }
        return SavedLocation(
            name: name,
            coordinate: Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            timeZoneID: zone.identifier
        )
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined else { return }
            authContinuation?.resume(returning: status)
            authContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: LocationError.unavailable)
            locationContinuation = nil
        }
    }
}
