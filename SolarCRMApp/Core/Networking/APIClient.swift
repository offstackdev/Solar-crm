import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

struct APIRequest {
    let path: String
    let method: HTTPMethod
    var body: Data?
    var headers: [String: String] = [:]
}

protocol APIClient {
    func send<T: Decodable>(_ request: APIRequest, decodeTo type: T.Type) async throws -> T
}

enum APIClientError: Error {
    case invalidURL
    case invalidResponse
}

struct SupabaseAPIClient: APIClient {
    let baseURL: URL
    let apiKey: String
    let sessionToken: String?

    func send<T: Decodable>(_ request: APIRequest, decodeTo type: T.Type) async throws -> T {
        guard let url = URL(string: request.path, relativeTo: baseURL) else {
            throw APIClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.setValue(apiKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let sessionToken {
            urlRequest.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }

        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct NoContentResponse: Decodable {}
