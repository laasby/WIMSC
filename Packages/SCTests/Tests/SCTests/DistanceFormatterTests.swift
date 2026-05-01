import Testing
import Foundation
import SCDomain

@Suite("DistanceFormatter")
struct DistanceFormatterTests {

    @Test func metricUnder1km() {
        let result = Formatters.distance(800, locale: Locale(identifier: "nb_NO"))
        #expect(result.contains("m"))
        #expect(!result.contains("km"))
    }

    @Test func metricOver1km() {
        let result = Formatters.distance(2500, locale: Locale(identifier: "nb_NO"))
        #expect(result.contains("km"))
    }

    @Test func imperialMiles() {
        let result = Formatters.distance(2000, locale: Locale(identifier: "en_US"))
        #expect(result.contains("mi"))
    }

    @Test func zeroDistanceHandled() {
        let result = Formatters.distance(0, locale: Locale(identifier: "nb_NO"))
        #expect(!result.isEmpty)
    }
}
