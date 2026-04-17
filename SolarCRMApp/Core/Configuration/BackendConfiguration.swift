import Foundation

struct BackendConfiguration {
    let supabaseURL: URL
    let supabaseAnonKey: String

    static func loadFromEnvironment() -> BackendConfiguration? {
        let env = ProcessInfo.processInfo.environment
        let infoDictionary = Bundle.main.infoDictionary ?? [:]

        guard
            let urlString = resolveValue(for: "SUPABASE_URL", env: env, infoDictionary: infoDictionary),
            let anonKey = resolveValue(for: "SUPABASE_ANON_KEY", env: env, infoDictionary: infoDictionary),
            let url = URL(string: urlString),
            !anonKey.isEmpty
        else {
            return nil
        }

        return BackendConfiguration(
            supabaseURL: url,
            supabaseAnonKey: anonKey
        )
    }

    private static func resolveValue(for key: String, env: [String: String], infoDictionary: [String: Any]) -> String? {
        if let envValue = env[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !envValue.isEmpty {
            return envValue
        }

        if let infoValue = infoDictionary[key] as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }
}
