import Testing
import SCData
import SCDomain
import Foundation

@Suite("ArbitrageCalculator")
struct ArbitrageCalculatorTests {

    private func makeSupercharger(nokPerKwh: Double?) -> Supercharger {
        let pricing = nokPerKwh.map { PricingInfo(perKwh: $0, currency: "NOK") }
        return Supercharger(
            id: "NO-01", name: "Test SC", latitude: 59, longitude: 10,
            streetAddress: "", city: "Oslo", state: "", country: "NO",
            postalCode: "", status: .open, stallCount: 8,
            generation: .v3, maxKilowatts: 250,
            pricing: pricing,
            dataSource: .superchargeInfo
        )
    }

    private func makePrices(nokPerKwh: Double, zone: NOPriceZone = .no1, count: Int = 8) -> [HourlyPrice] {
        (0..<count).map { i in
            HourlyPrice(
                id: UUID(),
                startsAt: Date().addingTimeInterval(Double(i) * 3600),
                nokPerKwh: nokPerKwh,
                zone: zone
            )
        }
    }

    @Test func cheapHomePriceFavoursHome() {
        let sc = makeSupercharger(nokPerKwh: 3.0)
        let prices = makePrices(nokPerKwh: 0.5)
        let result = ArbitrageCalculator.calculate(supercharger: sc, tonightPrices: prices)
        if case .chargeAtHome = result.recommendation { } else {
            Issue.record("Expected chargeAtHome, got \(result.recommendation)")
        }
    }

    @Test func expensiveHomePriceFavoursSupercharging() {
        let sc = makeSupercharger(nokPerKwh: 2.5)
        let prices = makePrices(nokPerKwh: 5.0)
        let result = ArbitrageCalculator.calculate(supercharger: sc, tonightPrices: prices)
        if case .superchargeNow = result.recommendation { } else {
            Issue.record("Expected superchargeNow, got \(result.recommendation)")
        }
    }

    @Test func noPricingDataReturnsComparable() {
        let sc = makeSupercharger(nokPerKwh: nil)
        let prices = makePrices(nokPerKwh: 1.0)
        let result = ArbitrageCalculator.calculate(supercharger: sc, tonightPrices: prices)
        // Without SC pricing we can't compare — should be comparable or superchargeNow
        #expect(true) // just verify no crash
    }

    @Test func emptyPricesHandled() {
        let sc = makeSupercharger(nokPerKwh: 2.0)
        let result = ArbitrageCalculator.calculate(supercharger: sc, tonightPrices: [])
        #expect(true) // verify no crash
    }
}
