import SwiftUI
import SwiftData
import SCData
import SCDomain

public struct ListView: View {
    @State private var viewModel: ListViewModel
    @State private var showFilterSheet: Bool = false

    public init(locationService: LocationService, modelContext: ModelContext) {
        _viewModel = State(wrappedValue: ListViewModel(
            locationService: locationService,
            modelContext: modelContext
        ))
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sites.isEmpty {
                    ContentUnavailableView(
                        "No Superchargers",
                        systemImage: "bolt.slash",
                        description: Text("Try adjusting your filters or search.")
                    )
                } else {
                    List {
                        ForEach(viewModel.sites, id: \.id) { site in
                            NavigationLink(value: site) {
                                SuperchargerRow(
                                    supercharger: site,
                                    userLocation: viewModel.locationService.currentLocation
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Superchargers")
            .searchable(text: $viewModel.searchText, prompt: "Search by name or city")
            .onChange(of: viewModel.searchText)      { _, _ in viewModel.applyFiltersAndSort() }
            .onChange(of: viewModel.filterCriteria)  { _, _ in viewModel.applyFiltersAndSort() }
            .onChange(of: viewModel.sortOrder)       { _, _ in viewModel.applyFiltersAndSort() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SortMenuButton(sortOrder: $viewModel.sortOrder)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(criteria: $viewModel.filterCriteria) {
                    showFilterSheet = false
                }
            }
            .task {
                await viewModel.reload()
            }
            .navigationDestination(for: Supercharger.self) { site in
                Text("Detail for \(site.name) — coming in M4")
                    .navigationTitle(site.name)
            }
        }
    }

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .overlay(alignment: .topTrailing) {
                    if viewModel.filterCriteria != .default {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
        }
    }
}
