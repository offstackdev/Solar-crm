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
