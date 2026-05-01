import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Map")
                .tabItem { Label("Map", systemImage: "map") }
            Text("List")
                .tabItem { Label("List", systemImage: "list.bullet") }
        }
    }
}
