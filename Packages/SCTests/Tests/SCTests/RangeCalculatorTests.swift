import Testing
import Foundation
import SCData
import SCDomain

@Suite("RangeCalculator")
struct RangeCalculatorTests {

    private func makeVehicle(
        batteryKwh: Double = 75,
        efficiencyWhPerKm: Double = 155,
        minArrivalSoc: Int = 10
    ) -> UserVehicle {
        UserVehicle(
            id: UUID(), name: "Test", model: .model3,
            batteryCapacityKwh: batteryKwh,
            efficiencyWhPerKm: efficiencyWhPerKm,
            wheelSizeInches: 18,
            preferredMinArrivalSoc: minArrivalSoc,
            isDefault: true
        )
    }

    @Test func fullChargeRangeIsPositive() {
        let v = makeVehicle()
        let range = RangeCalculator.rangeKm(vehicle: v, currentSocPercent: 100)
        #expect(range > 0)
    }

    @Test func rangeScalesWithSoc() {
        let v = makeVehicle()
        let full = RangeCalculator.rangeKm(vehicle: v, currentSocPercent: 100)
        let half = RangeCalculator.rangeKm(vehicle: v, currentSocPercent: 50)
        #expect(abs(half - full / 2) < 1.0)
    }

    @Test func coldWeatherReducesRange() {
        let v = makeVehicle()
        let warm = RangeCalculator.rangeKm(vehicle: v, currentSocPercent: 80, ambientCelsius: 20)
        let cold = RangeCalculator.rangeKm(vehicle: v, currentSocPercent: 80, ambientCelsius: -10)
        #expect(cold < warm)
    }

    @Test func canReachNearbyDestination() {
        let v = makeVehicle()
        let canReach = RangeCalculator.canReach(
            vehicle: v, currentSocPercent: 80,
            distanceKm: 50, arrivalSocPercent: 10
        )
        #expect(canReach)
    }

    @Test func cannotReachFarDestination() {
        let v = makeVehicle()
        let canReach = RangeCalculator.canReach(
            vehicle: v, currentSocPercent: 20,
            distanceKm: 500, arrivalSocPercent: 10
        )
        #expect(!canReach)
    }

    @Test func chargeTimeIsPositive() {
        let v = makeVehicle()
        let minutes = RangeCalculator.estimatedChargeMinutes(
            vehicle: v, fromSoc: 20, toSoc: 80,
            chargerGeneration: .v3
        )
        #expect(minutes > 0)
    }

    @Test func chargeTimeFasterAtHigherPower() {
        let v = makeVehicle()
        let v3Minutes = RangeCalculator.estimatedChargeMinutes(vehicle: v, fromSoc: 20, toSoc: 80, chargerGeneration: .v3)
        let v2Minutes = RangeCalculator.estimatedChargeMinutes(vehicle: v, fromSoc: 20, toSoc: 80, chargerGeneration: .v2)
        #expect(v3Minutes < v2Minutes)
    }

    @Test func zeroSocDeltaReturnsZero() {
        let v = makeVehicle()
        let minutes = RangeCalculator.estimatedChargeMinutes(vehicle: v, fromSoc: 80, toSoc: 80, chargerGeneration: .v3)
        #expect(minutes == 0)
    }
}
