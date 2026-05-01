import SwiftUI
import SwiftData
import SCData
import SCDomain

public struct VehicleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vehicleService: VehicleService
    @State private var showAddSheet = false

    public init(modelContext: ModelContext) {
        _vehicleService = State(initialValue: VehicleService(modelContext: modelContext))
    }

    public var body: some View {
        List {
            ForEach(vehicleService.vehicles) { vehicle in
                NavigationLink(value: vehicle) {
                    VehicleRow(vehicle: vehicle)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    try? vehicleService.deleteVehicle(vehicleService.vehicles[index])
                }
            }
        }
        .navigationTitle("My Vehicles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddVehicleView(modelContext: modelContext) {
                showAddSheet = false
                try? vehicleService.load()
            }
        }
        .navigationDestination(for: UserVehicle.self) { vehicle in
            VehicleDetailView(vehicle: vehicle, vehicleService: vehicleService)
        }
        .task { try? vehicleService.load() }
        .overlay {
            if vehicleService.vehicles.isEmpty {
                ContentUnavailableView(
                    "No Vehicles",
                    systemImage: "car",
                    description: Text("Add your Tesla to get personalised range and charge estimates.")
                )
            }
        }
    }
}
