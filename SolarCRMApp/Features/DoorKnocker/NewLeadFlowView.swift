import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct NewLeadFlowView: View {
    @EnvironmentObject private var appState: AppState

    @State private var draft = LeadFormDraft()
    @State private var extraction: LeadExtraction?
    @State private var selectedItem: PhotosPickerItem?
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

                if appState.supportsAIExtraction {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Import Notes Image", systemImage: "photo.on.rectangle")
                    }
                } else {
                    Label("Image Intake Coming Soon", systemImage: "photo.badge.exclamationmark")
                        .foregroundStyle(.secondary)
                }
            }

            Section("AI Intake") {
                Text(appState.supportsAIExtraction
                     ? "Upload a note screenshot or field photo. AI extracts likely lead details, then you verify every field before anything is saved."
                     : "Image-based AI extraction is disabled until a real backend OCR/AI flow is connected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(appState.supportsAIExtraction
                     ? "Image-created leads follow the same handoff flow as manual leads."
                     : "Use manual entry for live workflows.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                        Text("Continue with Manual Entry")
                    }
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
        .onChange(of: selectedItem) { _, newValue in
            guard newValue != nil else { return }
            Task {
                await runExtraction()
            }
        }
    }

    private func runExtraction() async {
        isExtracting = true
        extractionError = nil
        defer { isExtracting = false }

        do {
            guard let item = selectedItem else {
                throw BackendServiceError.requestFailed("Select an image before running AI intake.")
            }

            guard let imageData = try await item.loadTransferable(type: Data.self), !imageData.isEmpty else {
                throw BackendServiceError.requestFailed("The selected image could not be read.")
            }

            let contentType = item.supportedContentTypes.first ?? .jpeg
            let fileExtension = contentType.preferredFilenameExtension ?? "jpg"
            let payload = LeadImagePayload(
                data: imageData,
                fileName: "field-notes-\(UUID().uuidString.prefix(6)).\(fileExtension)",
                mimeType: contentType.preferredMIMEType ?? "image/jpeg"
            )

            let extracted = try await appState.extractLead(from: payload)
            extraction = extracted
            draft = extracted.draft
            showReviewScreen = true
            selectedItem = nil
        } catch {
            extractionError = error.localizedDescription
            selectedItem = nil
        }
    }
}
