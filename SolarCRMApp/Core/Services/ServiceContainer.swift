import Foundation

struct ServiceContainer {
    let authService: AuthServicing
    let leadService: LeadServicing
    let notificationService: NotificationServicing
    let aiExtractionService: AILeadExtracting
    let isUsingBackend: Bool
    let supportsAIExtraction: Bool

    static func bootstrap() -> ServiceContainer {
        if let configuration = BackendConfiguration.loadFromEnvironment() {
            let sessionStore = KeychainSessionStore()
            return ServiceContainer(
                authService: SupabaseAuthService(configuration: configuration, sessionStore: sessionStore),
                leadService: SupabaseLeadService(configuration: configuration, sessionStore: sessionStore),
                notificationService: SupabaseNotificationService(configuration: configuration, sessionStore: sessionStore),
                aiExtractionService: UnavailableAIExtractionService(),
                isUsingBackend: true,
                supportsAIExtraction: false
            )
        }

        return ServiceContainer(
            authService: MockAuthService(users: SeedData.users),
            leadService: MockLeadService(leads: SeedData.leads),
            notificationService: MockNotificationService(notifications: SeedData.notifications),
            aiExtractionService: UnavailableAIExtractionService(),
            isUsingBackend: false,
            supportsAIExtraction: false
        )
    }
}
