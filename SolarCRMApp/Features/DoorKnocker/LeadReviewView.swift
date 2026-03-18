import SwiftUI

struct LeadReviewView: View {
    let extraction: LeadExtraction
    let onSave: (LeadFormDraft) async -> Void

    @State private var draft: LeadFormDraft

    init(extraction: LeadExtraction, onSave: @escaping (LeadFormDraft) async -> Void) {
        self.extraction = extraction
        self.onSave = onSave
        _draft = State(initialValue: extraction.draft)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !extraction.lowConfidenceFields.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review low-confidence fields")
                        .font(.headline)
                    ForEach(extraction.lowConfidenceFields) { field in
                        HStack {
                            Text(field.fieldName)
                            Spacer()
                            Text("\(Int(field.confidence * 100))%")
                                .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08))
            }

            LeadFormView(
                title: "Verify Extracted Lead",
                draft: $draft,
                source: .imageIntake,
                showReviewContext: true
            ) {
                await onSave(draft)
            }
        }
    }
}
