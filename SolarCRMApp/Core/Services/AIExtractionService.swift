import Foundation

struct LeadImagePayload {
    let data: Data
    let fileName: String
    let mimeType: String
}

protocol AILeadExtracting {
    func extractLead(from image: LeadImagePayload) async throws -> LeadExtraction
}

struct UnavailableAIExtractionService: AILeadExtracting {
    func extractLead(from image: LeadImagePayload) async throws -> LeadExtraction {
        _ = image
        throw BackendServiceError.notImplemented("AI note extraction is not connected to a live backend yet. Use manual entry for now.")
    }
}

actor SupabaseAIExtractionService: AILeadExtracting {
    private let configuration: BackendConfiguration
    private let sessionStore: SessionStoring
    private let bucketName = "lead-intake-images"
    private let functionName = "lead-image-intake"
    private let maxRetryCount = 2

    init(configuration: BackendConfiguration, sessionStore: SessionStoring) {
        self.configuration = configuration
        self.sessionStore = sessionStore
    }

    func extractLead(from image: LeadImagePayload) async throws -> LeadExtraction {
        guard let session = await sessionStore.loadSession(), !session.isExpired else {
            throw BackendServiceError.requestFailed("Your session expired. Sign in again before importing an image.")
        }

        let objectPath = buildObjectPath(for: session.userID, fileName: image.fileName, mimeType: image.mimeType)
        try await upload(image: image, objectPath: objectPath, token: session.accessToken)
        let response = try await invokeExtraction(
            request: ExtractionRequest(bucket: bucketName, objectPath: objectPath, fileName: image.fileName, mimeType: image.mimeType),
            token: session.accessToken
        )

        let draft = LeadFormDraft(
            homeownerFullName: response.draft.homeownerFullName ?? "",
            phoneNumber: response.draft.phoneNumber ?? "",
            email: response.draft.email ?? "",
            propertyAddress: response.draft.propertyAddress ?? "",
            city: response.draft.city ?? "",
            state: response.draft.state ?? "",
            zipCode: response.draft.zipCode ?? "",
            utilityCompany: response.draft.utilityCompany ?? "",
            notes: response.draft.notes ?? "",
            appointmentDate: Date().addingTimeInterval(86_400),
            hasAppointment: false,
            leadSource: .imageIntake,
            homeownerType: response.draft.homeownerType ?? "Homeowner",
            averageElectricBill: response.draft.averageElectricBill ?? "",
            roofType: response.draft.roofType ?? "",
            shadingNotes: response.draft.shadingNotes ?? "",
            decisionMakerPresent: response.draft.decisionMakerPresent ?? true,
            spousePresentRequired: response.draft.spousePresentRequired ?? false,
            languagePreference: response.draft.languagePreference ?? "English"
        ).cleaned()

        return LeadExtraction(
            draft: draft,
            fieldConfidences: response.fieldConfidences.map { .init(fieldName: $0.fieldName, confidence: $0.confidence) },
            rawText: response.rawText
        )
    }

    private func upload(image: LeadImagePayload, objectPath: String, token: String) async throws {
        guard let encodedPath = objectPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "/storage/v1/object/\(bucketName)/\(encodedPath)", relativeTo: configuration.supabaseURL) else {
            throw BackendServiceError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = image.data
        request.setValue(configuration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(image.mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("3600", forHTTPHeaderField: "Cache-Control")
        request.setValue("false", forHTTPHeaderField: "x-upsert")

        let (data, response) = try await performData(for: request, operationName: "image upload")
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let message, !message.isEmpty {
                throw BackendServiceError.requestFailed("Image upload failed with status \(httpResponse.statusCode): \(message)")
            }
            throw BackendServiceError.requestFailed("Image upload failed with status \(httpResponse.statusCode).")
        }
    }

    private func invokeExtraction(request payload: ExtractionRequest, token: String) async throws -> ExtractionResponse {
        guard let url = URL(string: "/functions/v1/\(functionName)", relativeTo: configuration.supabaseURL) else {
            throw BackendServiceError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(payload)
        request.setValue(configuration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await performData(for: request, operationName: "OCR request")
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorPayload = try? JSONDecoder().decode(FunctionErrorResponse.self, from: data) {
                throw BackendServiceError.requestFailed(errorPayload.error)
            }
            if let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !message.isEmpty {
                throw BackendServiceError.requestFailed("Extraction request failed with status \(httpResponse.statusCode): \(message)")
            }
            throw BackendServiceError.requestFailed("OCR processing failed with status \(httpResponse.statusCode).")
        }

        if let decoded = try? JSONDecoder().decode(ExtractionResponse.self, from: data) {
            return decoded
        }

        if let errorPayload = try? JSONDecoder().decode(FunctionErrorResponse.self, from: data) {
            throw BackendServiceError.requestFailed(errorPayload.error)
        }

        if let manualResponse = tryDecodeExtractionResponse(from: data) {
            return manualResponse
        }

        if let message = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            throw BackendServiceError.requestFailed("Image intake returned an unreadable response: \(message)")
        }

        throw BackendServiceError.requestFailed("Image intake returned an unreadable empty response.")
    }

    private func buildObjectPath(for userID: UUID, fileName: String, mimeType: String) -> String {
        let sanitizedName = fileName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" || $0 == "_" }
        let fileExtension = sanitizedName.split(separator: ".").last.map(String.init) ?? defaultExtension(for: mimeType)
        let safeBaseName = sanitizedName.split(separator: ".").dropLast().joined(separator: ".")
        let baseName = safeBaseName.isEmpty ? "field-notes" : safeBaseName
        return "\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased())-\(baseName).\(fileExtension)"
    }

    private func defaultExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/png":
            return "png"
        case "image/heic", "image/heif":
            return "heic"
        case "image/webp":
            return "webp"
        default:
            return "jpg"
        }
    }

    private func performData(for request: URLRequest, operationName: String) async throws -> (Data, URLResponse) {
        var attempt = 0

        while true {
            do {
                return try await URLSession.shared.data(for: request)
            } catch {
                attempt += 1

                guard shouldRetry(error: error), attempt <= maxRetryCount else {
                    throw mapTransportError(error, operationName: operationName)
                }

                try? await Task.sleep(for: .milliseconds(350 * attempt))
            }
        }
    }

    private func shouldRetry(error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }

        switch urlError.code {
        case .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private func mapTransportError(_ error: Error, operationName: String) -> Error {
        guard let urlError = error as? URLError else { return error }

        switch urlError.code {
        case .networkConnectionLost, .timedOut, .notConnectedToInternet:
            return BackendServiceError.requestFailed("The \(operationName) was interrupted before Supabase finished responding. Check the connection and try the import again.")
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return BackendServiceError.requestFailed("Solar CRM could not reach the Supabase backend for the \(operationName). Confirm the device network and try again.")
        case .userAuthenticationRequired:
            return BackendServiceError.requestFailed("Your session needs to be refreshed before importing an image. Sign in again and retry.")
        default:
            return BackendServiceError.requestFailed(urlError.localizedDescription)
        }
    }

    private func tryDecodeExtractionResponse(from data: Data) -> ExtractionResponse? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let payload = jsonObject as? [String: Any],
            let draftPayload = payload["draft"] as? [String: Any]
        else {
            return nil
        }

        let fieldConfidencePayloads = (payload["fieldConfidences"] as? [[String: Any]] ?? []).compactMap {
            item -> ExtractionResponse.FieldConfidencePayload? in
            guard
                let fieldName = item["fieldName"] as? String,
                let confidence = item["confidence"] as? NSNumber
            else {
                return nil
            }

            return ExtractionResponse.FieldConfidencePayload(
                fieldName: fieldName,
                confidence: confidence.doubleValue
            )
        }

        let rawText = coerceString(payload["rawText"]) ?? coerceString(payload["raw_text"]) ?? ""

        return ExtractionResponse(
            draft: .init(
                homeownerFullName: coerceString(draftPayload["homeownerFullName"]),
                phoneNumber: coerceString(draftPayload["phoneNumber"]),
                email: coerceString(draftPayload["email"]),
                propertyAddress: coerceString(draftPayload["propertyAddress"]),
                city: coerceString(draftPayload["city"]),
                state: coerceString(draftPayload["state"]),
                zipCode: coerceString(draftPayload["zipCode"]),
                utilityCompany: coerceString(draftPayload["utilityCompany"]),
                notes: coerceString(draftPayload["notes"]),
                homeownerType: coerceString(draftPayload["homeownerType"]),
                averageElectricBill: coerceString(draftPayload["averageElectricBill"]),
                roofType: coerceString(draftPayload["roofType"]),
                shadingNotes: coerceString(draftPayload["shadingNotes"]),
                decisionMakerPresent: coerceBool(draftPayload["decisionMakerPresent"]),
                spousePresentRequired: coerceBool(draftPayload["spousePresentRequired"]),
                languagePreference: coerceString(draftPayload["languagePreference"])
            ),
            fieldConfidences: fieldConfidencePayloads,
            rawText: rawText
        )
    }

    private func coerceString(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }

    private func coerceBool(_ value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            return bool
        case let number as NSNumber:
            return number.boolValue
        case let string as String:
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

private struct ExtractionRequest: Encodable {
    let bucket: String
    let objectPath: String
    let fileName: String
    let mimeType: String
}

private struct ExtractionResponse: Decodable {
    struct DraftPayload: Decodable {
        let homeownerFullName: String?
        let phoneNumber: String?
        let email: String?
        let propertyAddress: String?
        let city: String?
        let state: String?
        let zipCode: String?
        let utilityCompany: String?
        let notes: String?
        let homeownerType: String?
        let averageElectricBill: String?
        let roofType: String?
        let shadingNotes: String?
        let decisionMakerPresent: Bool?
        let spousePresentRequired: Bool?
        let languagePreference: String?
    }

    struct FieldConfidencePayload: Decodable {
        let fieldName: String
        let confidence: Double
    }

    let draft: DraftPayload
    let fieldConfidences: [FieldConfidencePayload]
    let rawText: String
}

private struct FunctionErrorResponse: Decodable {
    let error: String
}
