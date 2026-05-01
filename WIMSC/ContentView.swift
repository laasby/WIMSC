import SwiftUI
import SwiftData
import SCData
import SCUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()

    var body: some View {
        TabView {
            MapView(locationService: locationService, modelContext: modelContext)
                .tabItem { Label("Map", systemImage: "map") }

            ListView(locationService: locationService, modelContext: modelContext)
                .tabItem { Label("List", systemImage: "list.bullet") }

            TripPlannerView()
                .tabItem { Label("Trip", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
