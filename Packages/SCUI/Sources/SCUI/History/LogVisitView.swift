import SwiftUI
import SwiftData
import SCData
import SCDomain

/// Sheet for manually logging a charging session.
public struct LogVisitView: View {
    public let supercharger: Supercharger
    @State private var historyService: VisitHistoryService
    @State private var kwhDelivered: String = ""
    @State private var cost: String = ""
    @State private var currency: String = "NOK"
    @State private var durationMinutes: String = ""
    @State private var startSoc: String = ""
    @State private var endSoc: String = ""
    @State private var stallNumber: String = ""
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    public var onDismiss: () -> Void

    public init(supercharger: Supercharger, modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        self.supercharger = supercharger
        _historyService = State(initialValue: VisitHistoryService(modelContext: modelContext))
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    HStack {
                        Text("kWh delivered")
                        Spacer()
                        TextField("e.g. 45.2", text: $kwhDelivered)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("e.g. 22", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Stall number")
                        Spacer()
                        TextField("Optional", text: $stallNumber)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Cost") {
                    HStack {
                        Text("Amount paid")
                        Spacer()
                        TextField("e.g. 89.50", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(["NOK", "SEK", "DKK", "EUR", "USD", "GBP"], id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }

                Section("State of Charge") {
                    HStack {
                        Text("Start SoC (%)")
                        Spacer()
                        TextField("e.g. 15", text: $startSoc)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("End SoC (%)")
                        Spacer()
                        TextField("e.g. 80", text: $endSoc)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let kwh = Double(kwhDelivered)
        let costVal = Double(cost)
        let dur = Int(durationMinutes)
        let start = Int(startSoc)
        let end = Int(endSoc)
        let stall = Int(stallNumber)
        let currencyVal = cost.isEmpty ? nil : currency

        try? historyService.addVisit(
            superchargerId: supercharger.id,
            kwhDelivered: kwh,
            cost: costVal,
            currency: currencyVal,
            durationMinutes: dur,
            startSoc: start,
            endSoc: end,
            ambientTempCelsius: nil,
            stallNumber: stall,
            notes: notes.isEmpty ? nil : notes
        )
        onDismiss()
    }
}
