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

    private var hasAppointmentTime: Bool {
        lead?.appointmentDate != nil
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

                        Button(action: saveAppointmentTime) {
                            HStack {
                                if isSavingAppointment {
                                    ProgressView()
                                }
                                Text(hasAppointmentTime ? "Update Appointment Time" : "Save Appointment Time")
                            }
                        }

                        if hasAppointmentTime {
                            Button("Appointment Confirmed", action: confirmAppointment)
                        }

                        if let appointmentSaveError {
                            Text(appointmentSaveError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Appointment Canceled", action: cancelAppointment)

                        if hasAppointmentTime {
                            Button("Appointment Rescheduled", action: rescheduleAppointment)
                        } else {
                            Text("Add an appointment time before this lead can be handed off to the closer.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .tint(AppTheme.primary)
        .task(id: lead?.appointmentDate) {
            appointmentDraft = lead?.appointmentDate ?? Date().addingTimeInterval(86_400)
        }
    }

    private func saveAppointmentTime() {
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
    }

    private func confirmAppointment() {
        updateStatus(.appointmentConfirmed, note: "Door knocker confirmed the appointment with prospect")
    }

    private func cancelAppointment() {
        updateStatus(.appointmentCanceled, note: "Door knocker canceled appointment after homeowner update")
    }

    private func rescheduleAppointment() {
        updateStatus(.appointmentRescheduled, note: "Door knocker rescheduled appointment")
    }

    private func updateStatus(_ status: LeadStatus, note: String) {
        Task {
            await appState.updateLeadStatus(
                leadID: leadID,
                status: status,
                note: note
            )
        }
    }
}
