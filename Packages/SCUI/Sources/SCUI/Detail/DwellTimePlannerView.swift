import SwiftUI
import SCData
import SCDomain

public struct DwellTimePlannerView: View {
    public let plan: DwellPlan

    public init(plan: DwellPlan) {
        self.plan = plan
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Charge time banner
            HStack {
                Image(systemName: "bolt.fill").foregroundStyle(.blue)
                Text("~\(plan.chargeMinutes) min to \(plan.targetSoc)%")
                    .font(.headline)
            }

            if plan.activities.isEmpty {
                Text("No amenity data for this site.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(plan.activities) { activity in
                    HStack(spacing: 10) {
                        Image(systemName: activity.category.systemImage)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(activity.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(activity.walkingMinutes) min walk · \(Int(activity.distanceMetres)) m")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let closes = activity.closesInMinutes {
                            Text("Closes in \(closes) min")
                                .font(.caption).foregroundStyle(.orange)
                        } else if activity.isOpen {
                            Text("Open")
                                .font(.caption).foregroundStyle(.blue)
                        }
                    }
                }
            }

            // Summary
            Text(plan.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}
