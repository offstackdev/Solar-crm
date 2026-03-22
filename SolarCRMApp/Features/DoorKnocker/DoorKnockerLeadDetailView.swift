import SwiftUI

struct DoorKnockerLeadDetailView: View {
    @EnvironmentObject private var appState: AppState
    let leadID: UUID
    @State private var appointmentDraft = Date().addingTimeInterval(86_400)
    @State private var isSavingAppointment = false
    @State private var appointmentSaveError: String?

    private var lead: Lead? {
        appState.leads.first(where: { $0.id == leadID })
    }

    var body: some View {
        List {
            if let lead {
                Section("Lead") {
                    LabeledContent("Homeowner", value: lead.homeownerFullName)
                    LabeledContent("Phone", value: lead.phoneNumber)
                    LabeledContent("Address", value: "\(lead.propertyAddress), \(lead.city), \(lead.state) \(lead.zipCode)")
                    LabeledContent("Utility", value: lead.utilityCompany)
                    LabeledContent("Appointment", value: lead.appointmentDateText)
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusBadge(status: lead.currentStatus)
                    }
                }

                Section("Actions") {
                    if lead.currentStatus.isVisibleOnDoorKnockerActiveBoard {
                        DatePicker("Appointment Time", selection: $appointmentDraft, in: Date()..., displayedComponents: [.date, .hourAndMinute])

                        Button {
                            Task {
                                isSavingAppointment = true
                                appointmentSaveError = nil
                                defer { isSavingAppointment = false }
                                let saved = await appState.updateLeadAppointment(
                                    leadID: leadID,
                                    appointmentDate: appointmentDraft
                                )
                                if !saved {
                                    appointmentSaveError = "Appointment time could not be saved. Try again."
                                }
                            }
                        } label: {
                            HStack {
                                if isSavingAppointment {
                                    ProgressView()
                                }
                                Text(lead.appointmentDate == nil ? "Save Appointment Time" : "Update Appointment Time")
                            }
                        }

                        if lead.appointmentDate != nil {
                            Button("Appointment Confirmed") {
                                Task {
                                    await appState.updateLeadStatus(
                                        leadID: leadID,
                                        status: .appointmentConfirmed,
                                        note: "Door knocker confirmed the appointment with prospect"
                                    )
                                }
                            }
                        } else {
                            Text("Add an appointment time before handing this lead to the closer.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let appointmentSaveError {
                            Text(appointmentSaveError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Appointment Canceled") {
                            Task {
                                await appState.updateLeadStatus(
                                    leadID: leadID,
                                    status: .appointmentCanceled,
                                    note: "Door knocker canceled appointment after homeowner update"
                                )
                            }
                        }

                        Button("Appointment Rescheduled") {
                            Task {
                                await appState.updateLeadStatus(
                                    leadID: leadID,
                                    status: .appointmentRescheduled,
                                    note: "Door knocker rescheduled appointment"
                                )
                            }
                        }
                    } else {
                        Text("This lead has been handed off. You can monitor updates here, but closer workflow controls are locked.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    Text(lead.notes.isEmpty ? "No notes" : lead.notes)
                }

                Section("History") {
                    ForEach(lead.statusHistory) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                StatusBadge(status: item.status)
                                Spacer()
                                Text(item.changedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.note)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Lead Detail")
        .onAppear {
            if let lead {
                appointmentDraft = lead.appointmentDate ?? Date().addingTimeInterval(86_400)
            }
        }
        .onChange(of: lead?.appointmentDate) { _, newValue in
            appointmentDraft = newValue ?? appointmentDraft
        }
    }
}
