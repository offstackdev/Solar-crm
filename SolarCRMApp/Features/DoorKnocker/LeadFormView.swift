import SwiftUI

struct LeadFormView: View {
    let title: String
    @Binding var draft: LeadFormDraft
    let source: LeadSource
    let showReviewContext: Bool
    let onSubmit: () async -> Void

    @State private var isSubmitting = false

    var body: some View {
        Form {
            if showReviewContext {
                Section("Review Required") {
                    Text("AI-filled values can be edited before the lead is saved.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Prospect") {
                TextField("Homeowner Full Name", text: $draft.homeownerFullName)
                TextField("Phone Number", text: $draft.phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email", text: $draft.email)
                    .keyboardType(.emailAddress)
                Picker("Homeowner Type", selection: $draft.homeownerType) {
                    Text("Homeowner").tag("Homeowner")
                    Text("Renter").tag("Renter")
                }
                Picker("Language", selection: $draft.languagePreference) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("Other").tag("Other")
                }
            }

            Section("Property") {
                TextField("Address", text: $draft.propertyAddress)
                TextField("City", text: $draft.city)
                TextField("State", text: $draft.state)
                TextField("Zip", text: $draft.zipCode)
                    .keyboardType(.numberPad)
                TextField("Utility Company", text: $draft.utilityCompany)
                TextField("Average Electric Bill", text: $draft.averageElectricBill)
                TextField("Roof Type", text: $draft.roofType)
                TextField("Shading Notes", text: $draft.shadingNotes)
            }

            Section("Appointment") {
                Toggle("Appointment Scheduled", isOn: $draft.hasAppointment)
                if draft.hasAppointment {
                    DatePicker("Date & Time", selection: $draft.appointmentDate, displayedComponents: [.date, .hourAndMinute])
                }
                Toggle("Decision Maker Present", isOn: $draft.decisionMakerPresent)
                Toggle("Spouse Present Required", isOn: $draft.spousePresentRequired)
            }

            Section("Lead Notes") {
                Picker("Lead Source", selection: $draft.leadSource) {
                    ForEach(LeadSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .disabled(source == .imageIntake)

                TextField("Notes", text: $draft.notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }

            Section {
                Button {
                    Task {
                        isSubmitting = true
                        defer { isSubmitting = false }
                        await onSubmit()
                    }
                } label: {
                    HStack {
                        if isSubmitting { ProgressView() }
                        Text("Save Lead")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!draft.isValidForSubmission || isSubmitting)
            }
        }
        .navigationTitle(title)
    }
}
