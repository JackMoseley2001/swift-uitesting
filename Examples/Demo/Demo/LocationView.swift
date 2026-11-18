import CoreLocation
import SwiftUI

/// Asks Core Location where the device is, and keeps the answer.
@MainActor
final class LocationFinder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinates = "Not asked"

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Asks for permission if the app does not have it, and then for the location.
    func find() {
        coordinates = "Looking"
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            manager.startUpdatingLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard coordinates == "Looking" else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways: self.manager.startUpdatingLocation()
            case .denied, .restricted: coordinates = "Denied"
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            coordinates = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {}
}

/// A button that asks where the device is, and a line of text that shows the answer,
/// so that UI tests can check the location they put the device at.
struct LocationView: View {
    @StateObject private var finder = LocationFinder()

    var body: some View {
        VStack(spacing: 24) {
            Text(finder.coordinates)
                .accessibilityIdentifier(LocationID.coordinates)

            Button("Find my location") {
                finder.find()
            }
            .accessibilityIdentifier(LocationID.findButton)
        }
        .padding()
    }
}
