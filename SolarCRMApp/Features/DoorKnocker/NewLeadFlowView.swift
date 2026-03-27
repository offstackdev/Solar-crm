import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct NewLeadFlowView: View {
    @EnvironmentObject private var appState: AppState

    @State private var draft = LeadFormDraft()

    private var assignedCloserName: String? {
        guard let assignedCloserID = appState.currentUser?.assignedCloserID else { return nil }
        return appState.userName(for: assignedCloserID)
    }

    var body: some View {
        AppScreen(title: "Add Lead") {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader("Choose how to start")
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
                    optionRow(
                        title: "Manual Entry",
                        message: "Type the lead details yourself.",
                        systemImage: "square.and.pencil"
                    )
                }

                if appState.supportsAIExtraction {
                    NavigationLink {
                        LeadImageImportView(assignedCloserName: assignedCloserName)
                    } label: {
                        optionRow(
                            title: "Import Notes Image",
                            message: "Capture a new photo or choose an existing image for AI review.",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                } else {
                    optionRow(
                        title: "Image Intake Coming Soon",
                        message: "Use manual entry for live workflows until AI image intake is enabled.",
                        systemImage: "photo.badge.exclamationmark"
                    )
                    .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader("AI Intake")
                AppSurface {
                    Text(appState.supportsAIExtraction
                         ? "Image-created leads follow the same review and handoff flow as manual leads. Nothing is saved until the extracted fields are verified."
                         : "Image-based AI extraction is disabled until a real backend OCR/AI flow is connected.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }
        }
        .navigationTitle("Add Lead")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func optionRow(title: String, message: String, systemImage: String) -> some View {
        AppOutlinedSurface {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .foregroundStyle(AppTheme.primary)
                    .padding(8)
                    .background(AppTheme.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.onSurface)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct LeadImageImportView: View {
    @EnvironmentObject private var appState: AppState

    let assignedCloserName: String?

    @State private var extraction: LeadExtraction?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showReviewScreen = false
    @State private var showExtractionLoading = false
    @State private var extractionError: String?
    @State private var showPhotoLibrary = false
    @State private var showCamera = false
    @State private var showFileImporter = false
    @State private var pendingPayload: LeadImagePayload?

    var body: some View {
        AppScreen(title: "Add Notes Image") {
            AppSurface {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Notes Image")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.onSurface)

                    Text("Capture a new photo or choose an existing image. AI will extract likely lead details, then you review every field before saving.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader("Choose Image Source")
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle") {
                        extractionError = nil
                        showPhotoLibrary = true
                    }

                    Button("Files", systemImage: "folder") {
                        extractionError = nil
                        showFileImporter = true
                    }
                } label: {
                    imageSourceRow(
                        title: "Import Image",
                        message: "Choose from Photo Library or Files.",
                        systemImage: "photo.on.rectangle"
                    )
                }
                .tint(.primary)

                Button {
                    openCamera()
                } label: {
                    imageSourceRow(
                        title: "Take Photo",
                        message: "Open the camera and capture field notes now.",
                        systemImage: "camera.fill"
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader("How It Works")
                AppSurface {
                    Text("After you select an image, Solar CRM sends it through the existing AI intake flow and opens a review screen before anything is saved.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }

            if let extractionErrorMessage = extractionError {
                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Image Issue")
                    AppSurface(fill: Color.red.opacity(0.08)) {
                        Text(extractionErrorMessage)
                            .foregroundStyle(.red)
                    }

                    Button("Try Another Image") {
                        extractionError = nil
                        showPhotoLibrary = true
                    }

                    NavigationLink {
                        ManualLeadEntryContainer(assignedCloserName: assignedCloserName)
                    } label: {
                        Text("Continue with Manual Entry")
                    }
                }
            }
        }
        .navigationTitle("Add Notes Image")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showExtractionLoading) {
            LeadExtractionLoadingView {
                await processPendingExtraction()
            }
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImportedFile(result)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureScreen { result in
                showCamera = false
                if let result {
                    switch result {
                    case .success(let imageData):
                        Task {
                            await beginExtractionFlow(
                                from: LeadImagePayload(
                                    data: imageData,
                                    fileName: "field-notes-\(UUID().uuidString.prefix(6)).jpg",
                                    mimeType: "image/jpeg"
                                )
                            )
                        }
                    case .failure(let error):
                        extractionError = error.localizedDescription
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showReviewScreen) {
            LeadReviewView(
                extraction: extraction ?? LeadExtraction(draft: LeadFormDraft(), fieldConfidences: [], rawText: ""),
                assignedCloserName: assignedCloserName
            ) { reviewedDraft in
                await appState.saveNewLead(from: reviewedDraft, source: .imageIntake)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }

            Task {
                await runExtraction(from: newValue)
            }
        }
    }

    private func imageSourceRow(
        title: String,
        message: String,
        systemImage: String,
        accentColor: Color = .blue,
        iconBackground: Color = Color.blue.opacity(0.10)
    ) -> some View {
        AppOutlinedSurface {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(accentColor)
                    .padding(10)
                    .background(iconBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.onSurface)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.onSurfaceVariant.opacity(0.6))
            }
        }
        .contentShape(Rectangle())
    }

    private func openCamera() {
        extractionError = nil

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            extractionError = "Camera is not available on this device. Import an existing image instead."
            return
        }

        showCamera = true
    }

    private func handleImportedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            Task {
                do {
                    let shouldStopAccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if shouldStopAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    let data = try Data(contentsOf: url)
                    guard !data.isEmpty else {
                        throw BackendServiceError.requestFailed("The selected image file could not be read.")
                    }

                    let contentType = UTType(filenameExtension: url.pathExtension) ?? .jpeg
                    let payload = LeadImagePayload(
                        data: data,
                        fileName: url.lastPathComponent.isEmpty ? "field-notes-\(UUID().uuidString.prefix(6)).\(contentType.preferredFilenameExtension ?? "jpg")" : url.lastPathComponent,
                        mimeType: contentType.preferredMIMEType ?? "image/jpeg"
                    )

                    await beginExtractionFlow(from: payload)
                } catch {
                    extractionError = error.localizedDescription
                }
            }
        case .failure(let error):
            extractionError = error.localizedDescription
        }
    }

    private func runExtraction(from item: PhotosPickerItem) async {
        do {
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

            await beginExtractionFlow(from: payload)
            selectedPhotoItem = nil
        } catch {
            extractionError = error.localizedDescription
            selectedPhotoItem = nil
        }
    }

    @MainActor
    private func beginExtractionFlow(from payload: LeadImagePayload) async {
        pendingPayload = payload
        extractionError = nil
        showExtractionLoading = true
    }

    @MainActor
    private func processPendingExtraction() async {
        guard let payload = pendingPayload else {
            showExtractionLoading = false
            extractionError = "The selected image could not be prepared for extraction."
            return
        }

        do {
            let extracted = try await appState.extractLead(from: payload)
            extraction = extracted
            pendingPayload = nil
            showExtractionLoading = false
            showReviewScreen = true
        } catch {
            pendingPayload = nil
            showExtractionLoading = false
            extractionError = error.localizedDescription
        }
    }
}

private struct LeadExtractionLoadingView: View {
    let onStart: () async -> Void

    @State private var hasStarted = false
    @State private var emojiIndex = 0

    private let emojis = ["📝", "✍️", "🤔", "🤝"]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Extracting Lead")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(emojis[emojiIndex])
                    .font(.system(size: 56))
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.easeInOut(duration: 0.22), value: emojiIndex)
            }
            .multilineTextAlignment(.center)
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            await onStart()
        }
        .task(id: hasStarted) {
            guard hasStarted else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(520))
                emojiIndex = (emojiIndex + 1) % emojis.count
            }
        }
    }
}

private struct CameraCaptureScreen: View {
    let completion: (Result<Data, Error>?) -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            CameraImagePicker(completion: completion)
                .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }
}

private struct ManualLeadEntryContainer: View {
    @EnvironmentObject private var appState: AppState

    let assignedCloserName: String?

    @State private var draft = LeadFormDraft()

    var body: some View {
        LeadFormView(
            title: "Manual Lead Entry",
            draft: $draft,
            source: draft.leadSource,
            showReviewContext: false,
            assignedCloserName: assignedCloserName
        ) {
            await appState.saveNewLead(from: draft)
        }
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    let completion: (Result<Data, Error>?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let completion: (Result<Data, Error>?) -> Void

        init(completion: @escaping (Result<Data, Error>?) -> Void) {
            self.completion = completion
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard
                let image = info[.originalImage] as? UIImage,
                let data = image.jpegData(compressionQuality: 0.88)
            else {
                completion(.failure(BackendServiceError.requestFailed("The captured photo could not be processed.")))
                return
            }

            completion(.success(data))
        }
    }
}
