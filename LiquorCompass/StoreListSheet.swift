import SwiftUI
import CoreLocation

struct StoreListSheet: View {
    @ObservedObject var finder: LiquorStoreFinder
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if finder.nearby.isEmpty {
                    Text(finder.isSearching ? "Searching…" : "No stores found nearby")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(finder.nearby) { store in
                        Button {
                            finder.select(store)
                            dismiss()
                        } label: {
                            row(for: store)
                        }
                        .listRowBackground(Color.white.opacity(store.id == finder.selected?.id ? 0.08 : 0.03))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.06, green: 0.06, blue: 0.08))
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if finder.userPickedSelection {
                        Button("Use nearest") {
                            finder.resetToNearest()
                            dismiss()
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func row(for store: LiquorStore) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.3))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let subtitle = subtitle(for: store) {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            Spacer()
            if let userLocation {
                Text(distanceString(from: userLocation, to: store.location))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
            }
            if store.id == finder.selected?.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.3))
            }
        }
        .padding(.vertical, 4)
    }

    private func subtitle(for store: LiquorStore) -> String? {
        let placemark = store.mapItem.placemark
        let parts = [placemark.thoroughfare, placemark.locality].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func distanceString(from user: CLLocation, to target: CLLocation) -> String {
        let meters = user.distance(from: target)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = meters < 1000 ? 0 : 1
        return formatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }
}
