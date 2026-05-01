import Testing
import SCDomain

struct SCDomainTests {
    @Test func moduleLoads() {
        // Smoke test: verify the module is importable and basic types exist
        let _ = FilterCriteria.default
        let _ = SortOrder.distance
    }
}
