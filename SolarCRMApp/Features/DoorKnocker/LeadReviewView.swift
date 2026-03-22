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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OCR spacing is cleaned for readability. Verify values against the original note before saving.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView {
                            Text(extraction.formattedRawText.isEmpty ? "No source text captured." : extraction.formattedRawText)
                                .font(.footnote.monospaced())
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 120, maxHeight: 220)
                        .padding(10)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    }
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
