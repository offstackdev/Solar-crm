import SwiftUI

struct LeadReviewView: View {
    let extraction: LeadExtraction
    let assignedCloserName: String?
    let onSave: (LeadFormDraft) async -> Bool

    @State private var draft: LeadFormDraft

    init(extraction: LeadExtraction, assignedCloserName: String?, onSave: @escaping (LeadFormDraft) async -> Bool) {
        self.extraction = extraction
        self.assignedCloserName = assignedCloserName
        self.onSave = onSave
        _draft = State(initialValue: extraction.draft)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Review")
                    .font(.headline)
                Text("Review and edit the extracted fields before saving. Nothing is auto-submitted.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !extraction.lowConfidenceFields.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Low-confidence fields")
                            .font(.subheadline.weight(.semibold))
                        ForEach(extraction.lowConfidenceFields) { field in
                            HStack {
                                Text(field.displayName)
                                Spacer()
                                Text("\(Int(field.confidence * 100))%")
                                    .foregroundStyle(.orange)
                            }
                            .font(.subheadline)
                        }
                    }
                }

                DisclosureGroup("Captured source text") {
                    Text(extraction.rawText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                }

                Text("This lead will save as Image Intake and follow the same closer handoff flow once the appointment is confirmed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))

            LeadFormView(
                title: "Verify Extracted Lead",
                draft: $draft,
                source: .imageIntake,
                showReviewContext: true,
                assignedCloserName: assignedCloserName
            ) {
                await onSave(draft)
            }
        }
    }
}
