import SwiftUI
import SCDomain

public struct SortMenuButton: View {
    @Binding public var sortOrder: SCDomain.SortOrder

    public init(sortOrder: Binding<SCDomain.SortOrder>) {
        _sortOrder = sortOrder
    }

    public var body: some View {
        Menu {
            Picker("Sort", selection: $sortOrder) {
                ForEach(SCDomain.SortOrder.allCases) { order in
                    Label(order.localizedName, systemImage: sortIcon(for: order))
                        .tag(order)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    private func sortIcon(for order: SCDomain.SortOrder) -> String {
        switch order {
        case .distance:       return "location"
        case .name:           return "textformat.abc"
        case .stallCount:     return "bolt.fill"
        case .maxKilowatts:   return "speedometer"
        case .recentlyVerified: return "clock"
        }
    }
}
