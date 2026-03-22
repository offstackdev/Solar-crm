import Foundation

struct BackendConfiguration {
    let supabaseURL: URL
    let supabaseAnonKey: String

    static func loadFromEnvironment() -> BackendConfiguration? {
        let env = ProcessInfo.processInfo.environment

        guard
            let urlString = env["SUPABASE_URL"],
            let anonKey = env["SUPABASE_ANON_KEY"],
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
}
