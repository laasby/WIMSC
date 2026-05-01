import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes

public struct ChargingSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var socPercent: Int
        public var kilowatts: Double
        public var nokAccumulated: Double
        public var minutesRemaining: Int
        public var queueDepth: Int
        public var targetSoc: Int
    }

    public var siteName: String
    public var stallNumber: Int?
    public var totalStalls: Int
}

// MARK: - Widget

struct ChargingSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChargingSessionAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.socPercent)%", systemImage: "battery.75")
                        .font(.title2.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label(String(format: "%.0f kW", context.state.kilowatts), systemImage: "bolt.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.siteName)
                            .font(.caption)
                        Spacer()
                        Text("\(context.state.minutesRemaining) min left")
                            .font(.caption.bold())
                        if context.state.queueDepth > 0 {
                            Label("\(context.state.queueDepth) in queue", systemImage: "person.2")
                                .font(.caption2).foregroundStyle(.orange)
                        }
                    }
                }
            } compactLeading: {
                Label("\(context.state.socPercent)%", systemImage: "bolt.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.yellow)
            } compactTrailing: {
                Text("\(context.state.minutesRemaining)m")
                    .font(.caption2.bold())
            } minimal: {
                Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ChargingSessionAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack {
                Text("\(context.state.socPercent)%")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("SoC")
                    .font(.caption2).foregroundStyle(.gray)
            }

            Divider().background(.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.siteName)
                    .font(.subheadline.bold()).foregroundStyle(.white)
                HStack {
                    Label(String(format: "%.0f kW", context.state.kilowatts), systemImage: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("·")
                    Text(String(format: "%.2f kr", context.state.nokAccumulated))
                        .foregroundStyle(.white)
                }
                .font(.caption)
                HStack {
                    Image(systemName: "clock")
                    Text("\(context.state.minutesRemaining) min to \(context.state.targetSoc)%")
                }
                .font(.caption).foregroundStyle(.gray)
                if context.state.queueDepth > 0 {
                    Label("\(context.state.queueDepth) waiting", systemImage: "person.2.fill")
                        .font(.caption2).foregroundStyle(.orange)
                }
            }
            Spacer()
        }
        .padding()
    }
}
