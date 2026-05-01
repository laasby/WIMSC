import SwiftUI
import MapKit
import UIKit
import SCData

public struct SuperchargerDetailView: View {
    public let supercharger: Supercharger
    public let locationService: LocationService
    @State private var viewModel: DetailViewModel
    @State private var showNavigateSheet = false

    public init(supercharger: Supercharger, locationService: LocationService) {
        self.supercharger = supercharger
        self.locationService = locationService
        _viewModel = State(wrappedValue: DetailViewModel(
            supercharger: supercharger,
            locationService: locationService
        ))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerCard
                miniMap
                specsSection
                pricingSection
                amenitiesSection
                weatherSection
                if supercharger.country == "NO" {
                    nordicSection
                }
                communitySection
                footer
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(supercharger.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { navigationButtons }
        .task { await viewModel.load() }
        .confirmationDialog(
            "Navigate to \(supercharger.name)",
            isPresented: $showNavigateSheet,
            titleVisibility: .visible
        ) {
            Button("Apple Maps") { openInAppleMaps() }
            if canOpenGoogleMaps {
                Button("Google Maps") { openInGoogleMaps() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(supercharger.name)
                .font(.title2.bold())

            Text(fullAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = "\(String(format: "%.5f", supercharger.latitude)), \(String(format: "%.5f", supercharger.longitude))"
            } label: {
                Text("\(String(format: "%.5f", supercharger.latitude)), \(String(format: "%.5f", supercharger.longitude))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                GenerationBadge(generation: supercharger.generation)
                if supercharger.hasMagicDock {
                    MagicDockBadge()
                }
                StatusDot(status: supercharger.status)
            }

            HStack(spacing: 6) {
                Text("⚡ \(supercharger.stallCount) stalls")
                Text("·")
                Text("\(supercharger.maxKilowatts) kW max")
                if supercharger.hasPullThrough {
                    Text("·")
                    Image(systemName: "arrow.right.to.line")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: supercharger.hasGatedAccess ? "lock" : "clock")
                Text(hoursText)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let dist = viewModel.distanceMetres {
                HStack(spacing: 6) {
                    Image(systemName: "car")
                    Text(formattedDistance(dist))
                    if let eta = viewModel.eta {
                        Text("·")
                        Text(eta)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    showNavigateSheet = true
                } label: {
                    Label("Navigate", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                ShareLink(item: shareURL) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    private var fullAddress: String {
        [supercharger.streetAddress, supercharger.city, supercharger.state, supercharger.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var hoursText: String {
        if supercharger.is24Hours { return "24/7" }
        return supercharger.openingHours ?? "Hours unknown"
    }

    private func formattedDistance(_ metres: Double) -> String {
        metres < 1000
            ? String(format: "%.0f m", metres)
            : String(format: "%.1f km", metres / 1000)
    }

    private var shareURL: URL {
        let encodedName = supercharger.name
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? supercharger.name
        return URL(string: "https://maps.apple.com/?ll=\(supercharger.latitude),\(supercharger.longitude)&q=\(encodedName)")
            ?? URL(string: "https://maps.apple.com/")!
    }

    // MARK: - Navigation helpers

    private func openInAppleMaps() {
        let coord = CLLocationCoordinate2D(
            latitude: supercharger.latitude,
            longitude: supercharger.longitude
        )
        let placemark = MKPlacemark(coordinate: coord)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = supercharger.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private var canOpenGoogleMaps: Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func openInGoogleMaps() {
        guard let url = URL(string: "comgooglemaps://?daddr=\(supercharger.latitude),\(supercharger.longitude)&directionsmode=driving") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Mini map

    @ViewBuilder
    private var miniMap: some View {
        let coord = CLLocationCoordinate2D(
            latitude: supercharger.latitude,
            longitude: supercharger.longitude
        )
        let region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        Map(position: .constant(.region(region))) {
            Marker(supercharger.name, coordinate: coord)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .disabled(true)
        .allowsHitTesting(false)
    }

    // MARK: - Specs section

    private var specsSection: some View {
        DetailSection(title: "Specifications") {
            let plugText = supercharger.plugTypes.isEmpty
                ? "Unknown"
                : supercharger.plugTypes.map(plugTypeLabel).joined(separator: ", ")
            DetailRow(
                label: "Generation",
                value: GenerationPinStyle.label(for: supercharger.generation),
                valueColor: GenerationPinStyle.color(for: supercharger.generation)
            )
            DetailRow(label: "Stalls", value: "\(supercharger.stallCount)")
            DetailRow(label: "Max Power", value: "\(supercharger.maxKilowatts) kW")
            DetailRow(label: "Plug Types", value: plugText)
            DetailRow(label: "Magic Dock / NACS+CCS", value: supercharger.hasMagicDock ? "✓" : "—")
            DetailRow(label: "Pull-Through", value: supercharger.hasPullThrough ? "✓" : "—")
            if supercharger.hasGatedAccess {
                DetailRow(
                    label: "Gated Access",
                    value: supercharger.gatedAccessNotes ?? "Yes"
                )
            }
        }
    }

    private func plugTypeLabel(_ plug: PlugType) -> String {
        switch plug {
        case .nacs:    return "NACS"
        case .ccs2:    return "CCS2"
        case .type2:   return "Type 2"
        case .chademo: return "CHAdeMO"
        }
    }

    // MARK: - Pricing section

    private var pricingSection: some View {
        DetailSection(title: "Pricing") {
            if let pricing = supercharger.pricing {
                if let kwh = pricing.perKwh {
                    DetailRow(
                        label: "Per kWh",
                        value: String(format: "%.2f \(pricing.currency)", kwh)
                    )
                }
                if let idle = pricing.idleFee {
                    DetailRow(
                        label: "Idle Fee",
                        value: String(format: "%.2f \(pricing.currency)/min", idle)
                    )
                }
                if let congestion = pricing.congestionFee {
                    DetailRow(
                        label: "Congestion Fee",
                        value: String(format: "%.2f \(pricing.currency)", congestion)
                    )
                }
                if let peak = pricing.peakHours {
                    DetailRow(label: "Peak Hours", value: peak)
                }
                if let notes = pricing.notes {
                    DetailRow(label: "Notes", value: notes)
                }
            } else {
                Text("Pricing info not available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Amenities section

    private var amenitiesSection: some View {
        DetailSection(title: "Amenities") {
            if supercharger.amenities.isEmpty {
                Text("No amenity data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(supercharger.amenities, id: \.self) { amenity in
                    HStack(spacing: 12) {
                        Image(systemName: amenitySymbol(amenity))
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(amenityLabel(amenity))
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
    }

    private func amenityLabel(_ amenity: Amenity) -> String {
        switch amenity {
        case .restrooms:      return "Restrooms"
        case .food:           return "Food"
        case .coffee:         return "Coffee"
        case .wifi:           return "Wi-Fi"
        case .shops:          return "Shops"
        case .coveredParking: return "Covered Parking"
        case .pullThrough:    return "Pull-Through"
        case .lounge:         return "Lounge"
        }
    }

    private func amenitySymbol(_ amenity: Amenity) -> String {
        switch amenity {
        case .restrooms:      return "toilet"
        case .food:           return "fork.knife"
        case .coffee:         return "cup.and.saucer"
        case .wifi:           return "wifi"
        case .shops:          return "bag"
        case .coveredParking: return "car.fill"
        case .pullThrough:    return "arrow.right.to.line"
        case .lounge:         return "sofa"
        }
    }

    // MARK: - Weather section

    @ViewBuilder
    private var weatherSection: some View {
        if let weather = viewModel.weather {
            DetailSection(title: "Weather") {
                if viewModel.isColdSoak {
                    HStack(spacing: 8) {
                        Text("❄️")
                        Text("Battery may be cold-soaked. Expect reduced charging speed until the pack warms up.")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 8)
                }

                HStack(spacing: 16) {
                    Image(systemName: weatherSymbol(weather.symbolCode))
                        .font(.largeTitle)
                        .foregroundStyle(weatherSymbolColor(weather.symbolCode))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.0f°C", weather.temperatureCelsius))
                            .font(.title2.bold())
                        Text(String(format: "Wind: %.1f m/s", weather.windSpeedMs))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(weather.timeseries.enumerated()), id: \.offset) { _, hour in
                            VStack(spacing: 4) {
                                Text(hourLabel(hour.time))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: weatherSymbol(hour.symbolCode))
                                    .foregroundStyle(weatherSymbolColor(hour.symbolCode))
                                Text(String(format: "%.0f°", hour.tempCelsius))
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func weatherSymbol(_ code: String) -> String {
        if code.contains("clearsky") { return "sun.max.fill" }
        if code.contains("fair") { return "cloud.sun.fill" }
        if code.contains("cloudy") || code.contains("overcast") { return "cloud.fill" }
        if code.contains("rain") { return "cloud.rain.fill" }
        if code.contains("snow") { return "cloud.snow.fill" }
        if code.contains("thunder") { return "cloud.bolt.fill" }
        return "cloud"
    }

    private func weatherSymbolColor(_ code: String) -> Color {
        if code.contains("clearsky") { return .yellow }
        if code.contains("rain") { return .blue }
        if code.contains("snow") { return .cyan }
        return .secondary
    }

    private func hourLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Nordic section

    @ViewBuilder
    private var nordicSection: some View {
        DetailSection(title: "Mountain Passes") {
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
        }
        DetailSection(title: "Electricity Prices") {
            Text("Spot price data available for Norwegian sites.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
        }
    }

    // MARK: - Community section

    private var communitySection: some View {
        DetailSection(title: "Recent Reports") {
            let notes = Array(
                supercharger.communityNotes
                    .sorted { $0.postedAt > $1.postedAt }
                    .prefix(5)
            )
            if notes.isEmpty {
                Text("No recent community reports.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(notes, id: \.id) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.body)
                            .font(.subheadline)
                        Text(note.postedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        let dateStr: String
        if let date = supercharger.lastVerifiedDate {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            dateStr = f.string(from: date)
        } else {
            dateStr = "Unknown"
        }
        return Text("Data: \(supercharger.dataSource.displayName) · Last verified: \(dateStr)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var navigationButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                supercharger.isFavourite.toggle()
            } label: {
                Image(systemName: supercharger.isFavourite ? "heart.fill" : "heart")
                    .foregroundStyle(supercharger.isFavourite ? Color.red : Color.secondary)
            }
        }
    }
}
