import Testing
import SCData
import SCDomain

@Suite("PreconditioningAdvisor")
struct PreconditioningAdvisorTests {

    private func makeSupercharger(generation: ChargerGeneration = .v4) -> Supercharger {
        Supercharger(
            id: "NO-02", name: "Test SC", latitude: 59, longitude: 10,
            streetAddress: "", city: "Bergen", state: "", country: "NO",
            postalCode: "", status: .open, stallCount: 12,
            generation: generation, maxKilowatts: generation.maxKilowatts,
            dataSource: .superchargeInfo
        )
    }

    @Test func warmWeatherNoPreconditioning() {
        let sc = makeSupercharger()
        let advice = PreconditioningAdvisor.advise(
            destination: sc, ambientCelsius: 15,
            vehicle: nil, distanceToChargerKm: 50
        )
        #expect(!advice.shouldPrecondition)
    }

    @Test func coldWeatherV4NeedsPreconditioning() {
        let sc = makeSupercharger(generation: .v4)
        let advice = PreconditioningAdvisor.advise(
            destination: sc, ambientCelsius: -15,
            vehicle: nil, distanceToChargerKm: 50
        )
        #expect(advice.shouldPrecondition)
        #expect(advice.warmPeakKw > advice.coldPeakKw)
    }

    @Test func v4NeedsLongerTriggerThanV2() {
        let v4 = makeSupercharger(generation: .v4)
        let v2 = makeSupercharger(generation: .v2)
        let adviceV4 = PreconditioningAdvisor.advise(destination: v4, ambientCelsius: -10, vehicle: nil, distanceToChargerKm: 100)
        let adviceV2 = PreconditioningAdvisor.advise(destination: v2, ambientCelsius: -10, vehicle: nil, distanceToChargerKm: 100)
        #expect(adviceV4.triggerDistanceKm >= adviceV2.triggerDistanceKm)
    }

    @Test func messageIsNonEmpty() {
        let sc = makeSupercharger()
        let advice = PreconditioningAdvisor.advise(
            destination: sc, ambientCelsius: -5,
            vehicle: nil, distanceToChargerKm: 30
        )
        #expect(!advice.message.isEmpty)
    }
}
