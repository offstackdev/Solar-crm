import PhotosUI
import SwiftUI

struct NewLeadFlowView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = LeadFormDraft()
    @State private var extraction: LeadExtraction?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageName = ""
    @State private var path: IntakePath?
    @State private var isExtracting = false
    @State private var extractionError: String?

    enum IntakePath: Hashable {
        case manual
        case reviewExtracted
    }

    var body: some View {
        List {
            Section("Create Lead") {
                NavigationLink(value: IntakePath.manual) {
                    Label("Manual Entry", systemImage: "square.and.pencil")
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Import Notes Image", systemImage: "photo.on.rectangle")
                }
            }

            if isExtracting {
                Section {
                    HStack {
                        ProgressView()
                        Text("Extracting lead details from image...")
                    }
                }
            }

            if let extractionError {
                Section {
                    Text(extractionError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("New Lead")
        .navigationDestination(item: $path) { path in
            switch path {
            case .manual:
                LeadFormView(
                    title: "Manual Lead Entry",
                    draft: $draft,
                    source: draft.leadSource,
                    showReviewContext: false
                ) {
                    await appState.saveNewLead(from: draft)
                    dismiss()
                }
            case .reviewExtracted:
                LeadReviewView(extraction: extraction ?? LeadExtraction(draft: draft, fieldConfidences: [], rawText: "")) { reviewedDraft in
                    await appState.saveNewLead(from: reviewedDraft, source: .imageIntake)
                    dismiss()
                }
            }
        }
        .task(id: selectedItem) {
            guard selectedItem != nil else { return }
            await runExtraction()
        }
    }

    private func runExtraction() async {
        isExtracting = true
        extractionError = nil
        defer { isExtracting = false }

        do {
            selectedImageName = "field-notes-\(UUID().uuidString.prefix(6))"
            let extracted = try await appState.extractLead(from: selectedImageName)
            extraction = extracted
            draft = extracted.draft
            path = .reviewExtracted
        } catch {
            extractionError = "AI extraction could not parse that image. Continue with manual entry instead."
        }
    }
}

extension NewLeadFlowView.IntakePath: Identifiable {
    var id: String {
        switch self {
        case .manual: return "manual"
        case .reviewExtracted: return "reviewExtracted"
        }
    }
}
