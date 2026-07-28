import Foundation

// MARK: - HTTPMethod

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - ContentType

enum ContentType: String {
    case json = "application/json"
    case formURLEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
    case textPlain = "text/plain"
}

// MARK: - Endpoint

/// Represents an API endpoint with all the information needed to build a URLRequest.
struct Endpoint {
    // MARK: - Properties

    /// The path component of the URL (e.g., "/users", "/posts/123")
    let path: String

    /// HTTP method for the request
    let method: HTTPMethod

    /// Query parameters to append to the URL
    let queryParameters: [String: any CustomStringConvertible & Sendable]?

    /// Custom headers for the request
    let headers: [String: String]?

    /// Request body data
    let body: Data?

    /// Content type for the request
    let contentType: ContentType

    /// Whether this endpoint requires authentication
    let requiresAuthentication: Bool

    // MARK: - Init

    init(path: String,
         method: HTTPMethod = .get,
         queryParameters: [String: any CustomStringConvertible & Sendable]? = nil,
         headers: [String: String]? = nil,
         body: Data? = nil,
         contentType: ContentType = .json,
         requiresAuthentication: Bool = true) {
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.headers = headers
        self.body = body
        self.contentType = contentType
        self.requiresAuthentication = requiresAuthentication
    }

    // MARK: - URL Building

    /// Builds the complete URL for this endpoint.
    /// - Parameters:
    ///   - baseURL: The base URL from the environment configuration.
    ///   - apiVersion: The API version string (e.g., "v1").
    /// - Returns: The complete URL, or nil if construction fails.
    func buildURL(baseURL: URL, apiVersion: String) -> URL? {
        let versionedPath = "/\(apiVersion)\(path)"

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        components.path = versionedPath

        if let queryParameters, !queryParameters.isEmpty {
            components.queryItems = queryParameters
                .sorted { $0.key < $1.key }
                .map { key, value in
                    URLQueryItem(name: key, value: String(describing: value))
                }
        }

        return components.url
    }

    // MARK: - Request Building

    /// Builds a URLRequest for this endpoint.
    /// - Parameters:
    ///   - baseURL: The base URL from the environment configuration.
    ///   - apiVersion: The API version string.
    /// - Returns: A configured URLRequest, or nil if URL construction fails.
    func buildRequest(baseURL: URL, apiVersion: String) -> URLRequest? {
        guard let url = buildURL(baseURL: baseURL, apiVersion: apiVersion) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - Endpoint + Encodable Body

extension Endpoint {
    /// Creates an endpoint with an Encodable body.
    /// - Parameters:
    ///   - path: The path component of the URL.
    ///   - method: HTTP method (defaults to POST).
    ///   - queryParameters: Optional query parameters.
    ///   - headers: Optional custom headers.
    ///   - body: The Encodable body object.
    ///   - encoder: JSONEncoder to use (defaults to a new instance).
    ///   - requiresAuthentication: Whether authentication is required.
    /// - Returns: A configured Endpoint.
    /// - Throws: Encoding errors if the body cannot be serialized.
    static func withBody(path: String,
                         method: HTTPMethod = .post,
                         queryParameters: [String: any CustomStringConvertible & Sendable]? = nil,
                         headers: [String: String]? = nil,
                         body: some Encodable & Sendable,
                         encoder: JSONEncoder = JSONEncoder(),
                         requiresAuthentication: Bool = true) throws -> Endpoint {
        let data = try encoder.encode(body)
        return Endpoint(path: path,
                        method: method,
                        queryParameters: queryParameters,
                        headers: headers,
                        body: data,
                        contentType: .json,
                        requiresAuthentication: requiresAuthentication)
    }

    /// Creates a GET endpoint with query parameters.
    /// - Parameters:
    ///   - path: The path component of the URL.
    ///   - queryParameters: Query parameters to include.
    ///   - headers: Optional custom headers.
    ///   - requiresAuthentication: Whether authentication is required.
    /// - Returns: A configured GET Endpoint.
    static func get(path: String,
                    queryParameters: [String: any CustomStringConvertible & Sendable]? = nil,
                    headers: [String: String]? = nil,
                    requiresAuthentication: Bool = true) -> Endpoint {
        Endpoint(path: path,
                 method: .get,
                 queryParameters: queryParameters,
                 headers: headers,
                 body: nil,
                 contentType: .json,
                 requiresAuthentication: requiresAuthentication)
    }

    /// Creates a POST endpoint with an Encodable body.
    static func post(path: String,
                     body: some Encodable & Sendable,
                     queryParameters: [String: any CustomStringConvertible & Sendable]? = nil,
                     headers: [String: String]? = nil,
                     encoder: JSONEncoder = JSONEncoder(),
                     requiresAuthentication: Bool = true) throws -> Endpoint {
        try withBody(path: path,
                     method: .post,
                     queryParameters: queryParameters,
                     headers: headers,
                     body: body,
                     encoder: encoder,
                     requiresAuthentication: requiresAuthentication)
    }

    /// Creates a PUT endpoint with an Encodable body.
    static func put(path: String,
                    body: some Encodable & Sendable,
                    queryParameters: [String: any CustomStringConvertible & Sendable]? = nil,
                    headers: [String: String]? = nil,
                    encoder: JSONEncoder = JSONEncoder(),
                    requiresAuthentication: Bool = true) throws -> Endpoint {
        try withBody(path: path,
                     method: .put,
                     queryParameters: queryParameters,
                     headers: headers,
                     body: body,
                     encoder: encoder,
                     requiresAuthentication: requiresAuthentication)
    }

    /// Creates a DELETE endpoint.
    static func delete(path: String,
                       queryParameters: [String: any CustomStringConvertible & Sendable]? = nil,
                       headers: [String: String]? = nil,
                       requiresAuthentication: Bool = true) -> Endpoint {
        Endpoint(path: path,
                 method: .delete,
                 queryParameters: queryParameters,
                 headers: headers,
                 body: nil,
                 contentType: .json,
                 requiresAuthentication: requiresAuthentication)
    }
}
