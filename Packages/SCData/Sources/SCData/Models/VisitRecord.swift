import Foundation
import SwiftData

/// A record of a user's charging session at a Supercharger.
@Model
public final class VisitRecord {
    public var id: UUID
    /// References the Supercharger by its site ID.
    public var superchargerId: String
    public var visitedAt: Date
    public var kwhDelivered: Double?
    public var cost: Double?
    public var currency: String?
    public var durationMinutes: Int?
    /// State of charge at session start (0–100%).
    public var startSoc: Int?
    /// State of charge at session end (0–100%).
    public var endSoc: Int?
    public var ambientTempCelsius: Double?
    public var stallNumber: Int?
    public var notes: String?
    public var source: VisitSource

    public init(
        id: UUID = UUID(),
        superchargerId: String,
        visitedAt: Date,
        kwhDelivered: Double? = nil,
        cost: Double? = nil,
        currency: String? = nil,
        durationMinutes: Int? = nil,
        startSoc: Int? = nil,
        endSoc: Int? = nil,
        ambientTempCelsius: Double? = nil,
        stallNumber: Int? = nil,
        notes: String? = nil,
        source: VisitSource = .manual
    ) {
        self.id = id
        self.superchargerId = superchargerId
        self.visitedAt = visitedAt
        self.kwhDelivered = kwhDelivered
        self.cost = cost
        self.currency = currency
        self.durationMinutes = durationMinutes
        self.startSoc = startSoc
        self.endSoc = endSoc
        self.ambientTempCelsius = ambientTempCelsius
        self.stallNumber = stallNumber
        self.notes = notes
        self.source = source
    }
}
