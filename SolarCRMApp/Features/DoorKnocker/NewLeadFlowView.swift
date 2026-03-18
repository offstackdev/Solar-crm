import PhotosUI
import SwiftUI

struct NewLeadFlowView: View {
    @EnvironmentObject private var appState: AppState

    @State private var draft = LeadFormDraft()
    @State private var extraction: LeadExtraction?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageName = ""
    @State private var showReviewScreen = false
    @State private var isExtracting = false
    @State private var extractionError: String?

    private var assignedCloserName: String? {
        guard let assignedCloserID = appState.currentUser?.assignedCloserID else { return nil }
        return appState.userName(for: assignedCloserID)
    }

    var body: some View {
        List {
            Section("Create Lead") {
                NavigationLink {
                    LeadFormView(
                        title: "Manual Lead Entry",
                        draft: $draft,
                        source: draft.leadSource,
                        showReviewContext: false,
                        assignedCloserName: assignedCloserName
                    ) {
                        await appState.saveNewLead(from: draft)
                    }
                } label: {
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
        .navigationDestination(isPresented: $showReviewScreen) {
            LeadReviewView(
                extraction: extraction ?? LeadExtraction(draft: draft, fieldConfidences: [], rawText: ""),
                assignedCloserName: assignedCloserName
            ) { reviewedDraft in
                await appState.saveNewLead(from: reviewedDraft, source: .imageIntake)
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
            showReviewScreen = true
        } catch {
            extractionError = "AI extraction could not parse that image. Continue with manual entry instead."
        }
    }
}
