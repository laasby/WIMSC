import SwiftUI
import SCData
import SCDomain

public struct FilterSheetView: View {
    @Binding public var criteria: FilterCriteria
    public var onDismiss: () -> Void

    // Power options: nil = no minimum
    private let powerOptions: [Int?] = [nil, 150, 250, 325]

    public init(criteria: Binding<FilterCriteria>, onDismiss: @escaping () -> Void) {
        _criteria = criteria
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: Generation
                Section {
                    ForEach([ChargerGeneration.v2, .v3, .v4], id: \.self) { gen in
                        Toggle(generationLabel(gen), isOn: setBinding(\.generations, value: gen))
                    }
                } header: {
                    Text("Generation")
                }
                .headerProminence(.increased)

                // MARK: Minimum Power
                Section {
                    Picker("Minimum Power", selection: $criteria.minimumKilowatts) {
                        ForEach(powerOptions, id: \.self) { kw in
                            Text(kw.map { "\($0) kW" } ?? "None")
                                .tag(kw)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Minimum Power")
                }
                .headerProminence(.increased)

                // MARK: Status
                Section {
                    ForEach(SiteStatus.allCases, id: \.self) { status in
                        Toggle(statusLabel(status), isOn: setBinding(\.statuses, value: status))
                    }
                } header: {
                    Text("Status")
                }
                .headerProminence(.increased)

                // MARK: Plug Types
                Section {
                    ForEach(PlugType.allCases, id: \.self) { plug in
                        Toggle(plugTypeLabel(plug), isOn: setBinding(\.plugTypes, value: plug))
                    }
                } header: {
                    Text("Plug Types")
                }
                .headerProminence(.increased)

                // MARK: Amenities
                Section {
                    ForEach(Amenity.allCases, id: \.self) { amenity in
                        Toggle(isOn: setBinding(\.amenities, value: amenity)) {
                            Label(amenityLabel(amenity), systemImage: amenitySymbol(amenity))
                        }
                    }
                } header: {
                    Text("Amenities")
                }
                .headerProminence(.increased)

                // MARK: Favourites
                Section {
                    Toggle("Favourites only", isOn: $criteria.favouritesOnly)
                } header: {
                    Text("Favourites")
                }
                .headerProminence(.increased)

                // MARK: Reset
                Section {
                    Button(role: .destructive) {
                        criteria = .default
                    } label: {
                        Text("Reset to defaults")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }

    // MARK: - Set binding helper

    private func setBinding<T: Hashable>(
        _ keyPath: WritableKeyPath<FilterCriteria, Set<T>>,
        value: T
    ) -> Binding<Bool> {
        Binding(
            get: { criteria[keyPath: keyPath].contains(value) },
            set: { included in
                if included {
                    criteria[keyPath: keyPath].insert(value)
                } else {
                    criteria[keyPath: keyPath].remove(value)
                }
            }
        )
    }

    // MARK: - Label helpers

    private func generationLabel(_ gen: ChargerGeneration) -> String {
        switch gen {
        case .v2: return "V2"
        case .v3: return "V3"
        case .v4: return "V4"
        case .unknown: return "Unknown"
        }
    }

    private func statusLabel(_ status: SiteStatus) -> String {
        switch status {
        case .open:         return "Open"
        case .construction: return "Under Construction"
        case .closed:       return "Closed"
        case .permit:       return "Permit"
        case .plan:         return "Planned"
        }
    }

    private func plugTypeLabel(_ plug: PlugType) -> String {
        switch plug {
        case .nacs:    return "NACS (Tesla)"
        case .ccs2:    return "CCS2"
        case .type2:   return "Type 2"
        case .chademo: return "CHAdeMO"
        }
    }

    private func amenityLabel(_ amenity: Amenity) -> String {
        switch amenity {
        case .restrooms:       return "Restrooms"
        case .food:            return "Food"
        case .coffee:          return "Coffee"
        case .wifi:            return "Wi-Fi"
        case .shops:           return "Shops"
        case .coveredParking:  return "Covered Parking"
        case .pullThrough:     return "Pull-Through"
        case .lounge:          return "Lounge"
        }
    }

    private func amenitySymbol(_ amenity: Amenity) -> String {
        switch amenity {
        case .restrooms:       return "toilet"
        case .food:            return "fork.knife"
        case .coffee:          return "cup.and.saucer"
        case .wifi:            return "wifi"
        case .shops:           return "bag"
        case .coveredParking:  return "car.fill"
        case .pullThrough:     return "arrow.right.to.line"
        case .lounge:          return "sofa"
        }
    }
}
