import SwiftUI

public struct DetailRow: View {
    public let label: String
    public let value: String
    public var valueColor: Color = .primary

    public init(label: String, value: String, valueColor: Color = .primary) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }

    public var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 6)
        Divider()
    }
}
