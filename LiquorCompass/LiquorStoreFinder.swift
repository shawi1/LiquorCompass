import Foundation
import MapKit

struct LiquorStore: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let location: CLLocation

    static func == (lhs: LiquorStore, rhs: LiquorStore) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class LiquorStoreFinder: ObservableObject {
    @Published var nearest: LiquorStore?
    @Published var isSearching = false

    private var lastSearchLocation: CLLocation?

    func searchIfNeeded(near location: CLLocation) async {
        if let last = lastSearchLocation, last.distance(from: location) < 250 {
            return
        }
        await search(near: location)
    }

    func search(near location: CLLocation) async {
        isSearching = true
        defer { isSearching = false }
        lastSearchLocation = location

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "liquor store"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 20000,
            longitudinalMeters: 20000
        )
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()
            let stores = response.mapItems.compactMap { item -> LiquorStore? in
                guard let loc = item.placemark.location else { return nil }
                return LiquorStore(name: item.name ?? "Liquor Store", location: loc)
            }
            nearest = stores.min(by: {
                $0.location.distance(from: location) < $1.location.distance(from: location)
            })
        } catch {
            nearest = nil
        }
    }
}
