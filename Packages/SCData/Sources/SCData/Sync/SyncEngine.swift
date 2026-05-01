import Foundation
import SwiftData
import Observation

/// Manages background synchronisation of Supercharger data from remote sources.
@Observable
@MainActor
public final class SyncEngine {
    /// The current sync operation state.
    public enum SyncState {
        case idle
        case syncing
        case failed(Error)
    }
    
    public private(set) var state: SyncState = .idle
    public private(set) var lastSyncedAt: Date?
    
    private let superchargeClient: SuperchargeInfoClient
    private let teslaClient: TeslaFindUsClient
    private let modelContext: ModelContext
    
    /// 24 hours between required syncs.
    private static let syncInterval: TimeInterval = 24 * 60 * 60
    
    public init(
        superchargeClient: SuperchargeInfoClient,
        teslaClient: TeslaFindUsClient,
        modelContext: ModelContext
    ) {
        self.superchargeClient = superchargeClient
        self.teslaClient = teslaClient
        self.modelContext = modelContext
    }
    
    /// True if no sync has occurred or the last sync was more than 24 hours ago.
    public var needsSync: Bool {
        guard let last = lastSyncedAt else { return true }
        return Date().timeIntervalSince(last) > Self.syncInterval
    }
    
    /// Performs a full sync: fetches all sites from supercharge.info and upserts into SwiftData.
    public func syncAll() async {
        guard case .idle = state else { return }
        state = .syncing
        do {
            let dtos = try await superchargeClient.fetchAllSites()
            try upsert(dtos: dtos)
            lastSyncedAt = .now
            state = .idle
        } catch {
            state = .failed(error)
        }
    }
    
    /// Delta sync: fetches only sites that have changed since `lastSyncedAt`.
    /// Falls back to `syncAll()` if no previous sync timestamp exists.
    public func syncDelta() async {
        guard lastSyncedAt != nil else {
            await syncAll()
            return
        }
        // supercharge.info does not have a delta endpoint; re-fetch all and upsert.
        await syncAll()
    }
    
    // MARK: - Private
    
    private func upsert(dtos: [SuperchargerDTO]) throws {
        // Fetch existing IDs for fast lookup
        let allExisting = try modelContext.fetch(FetchDescriptor<Supercharger>())
        var existingById = Dictionary(uniqueKeysWithValues: allExisting.map { ($0.id, $0) })
        
        for dto in dtos {
            let domainId = dto.locationId ?? "site-\(dto.id)"
            if let existing = existingById[domainId] {
                // Update mutable fields; preserve user data (isFavourite, userNotes)
                existing.name = dto.name
                existing.latitude = dto.gps?.lat ?? existing.latitude
                existing.longitude = dto.gps?.lng ?? existing.longitude
                existing.streetAddress = dto.address?.street ?? existing.streetAddress
                existing.city = dto.address?.city ?? existing.city
                existing.state = dto.address?.state ?? existing.state
                existing.country = dto.address?.country ?? existing.country
                existing.postalCode = dto.address?.zip ?? existing.postalCode
                existing.stallCount = dto.stallCount ?? existing.stallCount
                existing.maxKilowatts = dto.powerKilowatt ?? existing.maxKilowatts
                existing.is24Hours = dto.open24Hr ?? existing.is24Hours
                existing.lastSyncedAt = .now
                // Update status (soft fields only, never hard-delete)
                if let rawStatus = dto.status {
                    switch rawStatus.uppercased() {
                    case "OPEN": existing.status = .open
                    case "CONSTRUCTION": existing.status = .construction
                    case "CLOSED": existing.status = .closed
                    case "PERMIT": existing.status = .permit
                    case "PLAN": existing.status = .plan
                    default: break
                    }
                }
                existingById[domainId] = nil // mark as processed
            } else {
                let newSite = dto.toDomain()
                modelContext.insert(newSite)
            }
        }
        try modelContext.save()
    }
}
