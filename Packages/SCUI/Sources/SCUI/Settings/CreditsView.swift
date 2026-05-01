import SwiftUI

public struct CreditsView: View {
    private let sources: [(name: String, description: String, url: String)] = [
        ("supercharge.info", "Primary Supercharger database", "https://supercharge.info"),
        ("Tesla Find Us", "Secondary site data", "https://www.tesla.com/findus"),
        ("MET Norway", "Weather data (Locationforecast 2.0)", "https://api.met.no"),
        ("Vegvesen", "Norwegian road & pass status", "https://www.vegvesen.no"),
        ("Tibber", "Electricity spot prices (optional)", "https://tibber.com"),
        ("OpenChargeMap", "Fallback charge point data", "https://openchargemap.org"),
    ]

    public init() {}

    public var body: some View {
        List(sources, id: \.name) { source in
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.subheadline.weight(.medium))
                Text(source.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link(source.url, destination: URL(string: source.url)!)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Data Sources")
    }
}
