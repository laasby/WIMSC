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

            Text("List — coming in M3")
                .tabItem { Label("List", systemImage: "list.bullet") }
        }
    }
}
