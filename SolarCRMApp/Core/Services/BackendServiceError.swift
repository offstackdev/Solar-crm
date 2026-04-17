import Foundation

enum BackendServiceError: LocalizedError {
    case notConfigured
    case notImplemented(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Backend configuration is missing."
        case .notImplemented(let message):
            return message
        case .requestFailed(let message):
            return message
        }
    }
}
