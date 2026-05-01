import Foundation
import SCData
import SCDomain

@Observable
public final class NordicViewModel {
    public private(set) var mountainPasses: [MountainPass] = []
    public private(set) var spotPrices: [NOPriceZone: [HourlyPrice]] = [:]
    public private(set) var arbitrageResult: ArbitrageResult?
    public private(set) var isLoading: Bool = false

    private let vegvesenClient: VegvesenClient
    private let spotPriceClient: SpotPriceClient

    public init(
        vegvesenClient: VegvesenClient = VegvesenClient(),
        spotPriceClient: SpotPriceClient = SpotPriceClient()
    ) {
        self.vegvesenClient = vegvesenClient
        self.spotPriceClient = spotPriceClient
    }

    public func load(for supercharger: Supercharger, homeZone: NOPriceZone = .no1) async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPasses() }
            group.addTask { await self.loadPrices(supercharger: supercharger, homeZone: homeZone) }
        }
    }

    private func loadPasses() async {
        mountainPasses = await vegvesenClient.fetchMountainPasses()
    }

    private func loadPrices(supercharger: Supercharger, homeZone: NOPriceZone) async {
        spotPrices = await spotPriceClient.fetchAllZones()
        let tonightPrices = spotPrices[homeZone] ?? []
        arbitrageResult = ArbitrageCalculator.calculate(
            supercharger: supercharger,
            tonightPrices: tonightPrices
        )
    }

    /// Returns passes relevant to the given destination.
    /// Currently returns all passes; refined proximity filtering comes in M10.
    public func relevantPasses(for supercharger: Supercharger) -> [MountainPass] {
        mountainPasses
    }
}
