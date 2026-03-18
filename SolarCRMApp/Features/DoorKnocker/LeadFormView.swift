import SwiftUI

struct LeadFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var draft: LeadFormDraft
    let source: LeadSource
    let showReviewContext: Bool
    let assignedCloserName: String?
    let onSubmit: () async -> Bool

    @State private var isSubmitting = false
    @State private var saveError: String?

    var body: some View {
        Form {
            if let assignedCloserName {
                Section("Routing") {
                    LabeledContent("Assigned Closer", value: assignedCloserName)
                    Text("This lead stays with you until the appointment is confirmed, then it moves to the closer's queue automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if showReviewContext {
                Section("Review Required") {
                    Text("AI-filled values can be edited before the lead is saved.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Required") {
                Text("Fields marked with * are required before saving.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !draft.isValidForSubmission {
                    Text("Missing: \(draft.missingRequiredFields.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Prospect") {
                TextField("Homeowner Full Name *", text: $draft.homeownerFullName)
                TextField("Phone Number *", text: $draft.phoneNumber)
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
                TextField("Address *", text: $draft.propertyAddress)
                TextField("City *", text: $draft.city)
                TextField("State *", text: $draft.state)
                TextField("Zip *", text: $draft.zipCode)
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

            if let saveError {
                Section {
                    Text(saveError)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        isSubmitting = true
                        saveError = nil
                        defer { isSubmitting = false }
                        let saved = await onSubmit()
                        if saved {
                            dismiss()
                        } else {
                            saveError = "Lead could not be saved. Try again."
                        }
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
