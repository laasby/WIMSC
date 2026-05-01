import Testing
import Foundation
import SCData
import SCDomain

@Suite("SuperchargerFilter")
struct FilterTests {

    private func makeSite(
        id: String = UUID().uuidString,
        name: String = "Test Site",
        status: SiteStatus = .open,
        generation: ChargerGeneration = .v3,
        maxKw: Int = 250,
        country: String = "NO",
        stallCount: Int = 8,
        isFavourite: Bool = false,
        amenities: [Amenity] = [],
        plugTypes: [PlugType] = [.nacs]
    ) -> Supercharger {
        Supercharger(
            id: id, name: name, latitude: 59.0, longitude: 10.0,
            streetAddress: "", city: "Oslo", state: "", country: country,
            postalCode: "", status: status, stallCount: stallCount,
            generation: generation, maxKilowatts: maxKw,
            dataSource: .superchargeInfo,
            isFavourite: isFavourite
        )
    }

    @Test func filterByStatus() {
        let sites = [
            makeSite(status: .open),
            makeSite(status: .closed),
            makeSite(status: .construction),
        ]
        let criteria = FilterCriteria(statuses: [.open])
        let result = SuperchargerFilter.apply(sites, criteria: criteria, sortBy: .name, userLocation: nil)
        #expect(result.count == 1)
        #expect(result.first?.status == .open)
    }

    @Test func filterByGeneration() {
        let sites = [makeSite(generation: .v2), makeSite(generation: .v3), makeSite(generation: .v4)]
        let criteria = FilterCriteria(generations: [.v4], statuses: [])
        let result = SuperchargerFilter.apply(sites, criteria: criteria, sortBy: .name, userLocation: nil)
        #expect(result.count == 1)
        #expect(result.first?.generation == .v4)
    }

    @Test func filterByMinKilowatts() {
        let sites = [makeSite(maxKw: 150), makeSite(maxKw: 250), makeSite(maxKw: 325)]
        let criteria = FilterCriteria(minimumKilowatts: 250, statuses: [])
        let result = SuperchargerFilter.apply(sites, criteria: criteria, sortBy: .name, userLocation: nil)
        #expect(result.count == 2)
    }

    @Test func filterByCountry() {
        let sites = [makeSite(country: "NO"), makeSite(country: "US"), makeSite(country: "DE")]
        let criteria = FilterCriteria(statuses: [], countries: ["NO"])
        let result = SuperchargerFilter.apply(sites, criteria: criteria, sortBy: .name, userLocation: nil)
        #expect(result.count == 1)
        #expect(result.first?.country == "NO")
    }

    @Test func filterFavouritesOnly() {
        let sites = [makeSite(isFavourite: true), makeSite(isFavourite: false)]
        let criteria = FilterCriteria(statuses: [], favouritesOnly: true)
        let result = SuperchargerFilter.apply(sites, criteria: criteria, sortBy: .name, userLocation: nil)
        #expect(result.count == 1)
        #expect(result.first?.isFavourite == true)
    }

    @Test func sortByName() {
        let sites = [makeSite(name: "Zebra SC"), makeSite(name: "Alpha SC"), makeSite(name: "Mango SC")]
        let result = SuperchargerFilter.apply(sites, criteria: .default, sortBy: .name, userLocation: nil)
        #expect(result.map(\.name) == ["Alpha SC", "Mango SC", "Zebra SC"])
    }

    @Test func sortByStallCount() {
        let sites = [makeSite(stallCount: 4), makeSite(stallCount: 12), makeSite(stallCount: 8)]
        let result = SuperchargerFilter.apply(sites, criteria: FilterCriteria(statuses: []), sortBy: .stallCount, userLocation: nil)
        #expect(result.map(\.stallCount) == [12, 8, 4])
    }

    @Test func emptyInputReturnsEmpty() {
        let result = SuperchargerFilter.apply([], criteria: .default, sortBy: .name, userLocation: nil)
        #expect(result.isEmpty)
    }

    @Test func defaultCriteriaShowsOnlyOpenSites() {
        let sites = [makeSite(status: .open), makeSite(status: .closed), makeSite(status: .plan)]
        let result = SuperchargerFilter.apply(sites, criteria: .default, sortBy: .name, userLocation: nil)
        #expect(result.allSatisfy { $0.status == .open })
    }
}
