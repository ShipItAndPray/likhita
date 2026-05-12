import Foundation

/// Errors raised by ``APIClient``. Surfaced to the UI for retry/backoff.
public enum APIError: Error, Sendable {
    case invalidURL
    case transport(URLError)
    case http(status: Int, body: Data)
    case decoding(Error)
    case unauthenticated
    case rateLimited(retryAfter: TimeInterval?)
}

/// Minimal async/await HTTP client that always sends `X-App-Origin`
/// (SPEC.md §17 / §19) and a Clerk bearer token when available.
public actor APIClient {
    public typealias TokenProvider = @Sendable () async -> String?
    public typealias HeaderProvider = @Sendable () async -> [String: String]

    private let baseURL: URL
    private let appOrigin: String
    private let session: URLSession
    private let tokenProvider: TokenProvider
    private let extraHeaders: HeaderProvider
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        appOrigin: String,
        session: URLSession = .shared,
        tokenProvider: @escaping TokenProvider = { nil },
        extraHeaders: @escaping HeaderProvider = { [:] }
    ) {
        self.baseURL = baseURL
        self.appOrigin = appOrigin
        self.session = session
        self.tokenProvider = tokenProvider
        self.extraHeaders = extraHeaders

        // Wire-format contract: every backend route uses **camelCase** keys
        // in both request and response bodies (matches the Drizzle schema /
        // Zod input/output types). Do NOT convert to/from snake_case —
        // doing that silently mismatches the Zod validators and produces
        // 400 "Required" errors for every multi-word field. Bug we hit
        // 2026-05-12 in the Sangha POST: `device_id` reached the server
        // when the schema expected `deviceId`.
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
    }

    /// `GET /v1/<path>` returning `T`.
    public func get<T: Decodable>(_ path: String, as: T.Type = T.self) async throws -> T {
        let request = try await buildRequest(path: path, method: "GET", body: Optional<Data>.none)
        return try await execute(request: request)
    }

    /// `POST /v1/<path>` with JSON body, returning `T`.
    public func post<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        as: T.Type = T.self
    ) async throws -> T {
        let data = try encoder.encode(body)
        let request = try await buildRequest(path: path, method: "POST", body: data)
        return try await execute(request: request)
    }

    // MARK: - Internal

    private func buildRequest(
        path: String,
        method: String,
        body: Data?
    ) async throws -> URLRequest {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: trimmed, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(appOrigin, forHTTPHeaderField: "X-App-Origin")
        if let token = await tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let extra = await extraHeaders()
        for (key, value) in extra {
            req.setValue(value, forHTTPHeaderField: key)
        }
        if let body { req.httpBody = body }
        return req
    }

    private func execute<T: Decodable>(request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw APIError.transport(urlError)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, body: data)
        }
        switch http.statusCode {
        case 200..<300:
            do { return try decoder.decode(T.self, from: data) }
            catch { throw APIError.decoding(error) }
        case 401:
            throw APIError.unauthenticated
        case 429:
            let retryAfter = (http.value(forHTTPHeaderField: "Retry-After")).flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retryAfter)
        default:
            throw APIError.http(status: http.statusCode, body: data)
        }
    }
}
