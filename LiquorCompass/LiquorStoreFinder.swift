import Foundation
import MapKit

struct LiquorStore: Identifiable, Equatable {
    let id: String
    let name: String
    let location: CLLocation
    let mapItem: MKMapItem

    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        self.name = mapItem.name ?? "Liquor Store"
        let loc = mapItem.placemark.location
            ?? CLLocation(latitude: mapItem.placemark.coordinate.latitude,
                          longitude: mapItem.placemark.coordinate.longitude)
        self.location = loc
        // Stable identity across re-searches so manual selection survives.
        self.id = "\(loc.coordinate.latitude),\(loc.coordinate.longitude)|\(self.name)"
    }

    static func == (lhs: LiquorStore, rhs: LiquorStore) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class LiquorStoreFinder: ObservableObject {
    @Published var nearby: [LiquorStore] = []
    @Published var selected: LiquorStore?
    @Published var isSearching = false
    @Published private(set) var userPickedSelection = false

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
            let stores = response.mapItems
                .map { LiquorStore(mapItem: $0) }
                .sorted { $0.location.distance(from: location) < $1.location.distance(from: location) }

            nearby = stores

            if userPickedSelection,
               let current = selected,
               let preserved = stores.first(where: { $0.id == current.id }) {
                selected = preserved
            } else {
                userPickedSelection = false
                selected = stores.first
            }
        } catch {
            nearby = []
            selected = nil
        }
    }

    func select(_ store: LiquorStore) {
        selected = store
        userPickedSelection = true
    }

    func resetToNearest() {
        userPickedSelection = false
        selected = nearby.first
    }
}
