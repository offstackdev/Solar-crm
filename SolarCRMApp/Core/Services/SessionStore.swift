import Foundation
import Security

protocol SessionStoring {
    func loadSession() async -> SupabaseSession?
    func saveSession(_ session: SupabaseSession) async
    func clearSession() async
}

actor KeychainSessionStore: SessionStoring {
    private let service = "com.suncrest.solarcrm.session"
    private let account = "supabase_session"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadSession() async -> SupabaseSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? decoder.decode(SupabaseSession.self, from: data)
    }

    func saveSession(_ session: SupabaseSession) async {
        guard let data = try? encoder.encode(session) else { return }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func clearSession() async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

actor InMemorySessionStore: SessionStoring {
    private var session: SupabaseSession?

    func loadSession() async -> SupabaseSession? {
        session
    }

    func saveSession(_ session: SupabaseSession) async {
        self.session = session
    }

    func clearSession() async {
        session = nil
    }
}
