import SwiftUI
import CoreLocation
import Combine

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var finder = LiquorStoreFinder()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.10), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 20)

                Spacer()

                compass
                    .padding(.vertical, 20)

                Spacer()

                distanceLabel
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)

            if !isAuthorized {
                permissionOverlay
            }
        }
        .onAppear { locationManager.start() }
        .onReceive(locationManager.$location.compactMap { $0 }) { newLocation in
            Task { await finder.searchIfNeeded(near: newLocation) }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 6) {
            Text("NEAREST LIQUOR STORE")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .tracking(3)
                .foregroundColor(.white.opacity(0.45))

            Text(finder.nearest?.name ?? (finder.isSearching ? "Searching…" : "—"))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 60)
        }
    }

    private var compass: some View {
        ZStack {
            CompassDial(heading: locationManager.heading)
            CompassNeedle()
                .rotationEffect(.degrees(arrowAngle))
                .animation(.easeInOut(duration: 0.35), value: arrowAngle)
                .opacity(finder.nearest == nil ? 0.25 : 1)
        }
        .frame(width: 320, height: 320)
    }

    private var distanceLabel: some View {
        VStack(spacing: 8) {
            Text(formattedDistance)
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            Text("AWAY")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(4)
                .foregroundColor(.white.opacity(0.45))
        }
    }

    private var permissionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.8))
            Text("Location access needed")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text("Enable location in Settings so the compass can point you to the nearest liquor store.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(40)
    }

    // MARK: - Derived

    private var isAuthorized: Bool {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .notDetermined: return true
        default: return false
        }
    }

    private var arrowAngle: Double {
        guard let userLocation = locationManager.location,
              let store = finder.nearest else { return 0 }
        let bearing = bearingDegrees(from: userLocation, to: store.location)
        return bearing - locationManager.heading
    }

    private var formattedDistance: String {
        guard let userLocation = locationManager.location,
              let store = finder.nearest else { return "—" }
        let meters = userLocation.distance(from: store.location)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = meters < 1000 ? 0 : 1
        return formatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }

    private func bearingDegrees(from: CLLocation, to: CLLocation) -> Double {
        let lat1 = from.coordinate.latitude * .pi / 180
        let lat2 = to.coordinate.latitude * .pi / 180
        let dLon = (to.coordinate.longitude - from.coordinate.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - Compass dial (tick marks + cardinal letters)

struct CompassDial: View {
    let heading: CLLocationDirection

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.04), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)

            // Tick marks every 5°, with major ticks every 30°
            ForEach(0..<72) { i in
                Rectangle()
                    .fill(Color.white.opacity(i % 6 == 0 ? 0.75 : 0.22))
                    .frame(width: i % 6 == 0 ? 2 : 1,
                           height: i % 6 == 0 ? 14 : 7)
                    .offset(y: -148)
                    .rotationEffect(.degrees(Double(i) * 5))
            }

            // Cardinal letters
            ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { idx, label in
                Text(label)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(label == "N" ? Color(red: 1.0, green: 0.45, blue: 0.3) : .white.opacity(0.85))
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(idx) * 90))
        }
        }
        .rotationEffect(.degrees(-heading))
        .animation(.easeInOut(duration: 0.2), value: heading)
    }
}

// MARK: - Needle pointing to target

struct CompassNeedle: View {
    var body: some View {
        ZStack {
            // Subtle inner ring
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                .frame(width: 240, height: 240)

            // Top half (red — points to store)
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.27, blue: 0.27),
                                 Color(red: 0.85, green: 0.18, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 110)
                .offset(y: -55)
                .shadow(color: Color.red.opacity(0.45), radius: 14, y: -2)

            // Bottom half (white-ish counterweight)
            Triangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 30, height: 110)
                .rotationEffect(.degrees(180))
                .offset(y: 55)

            // Center pivot
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.35), radius: 6)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ContentView()
}
