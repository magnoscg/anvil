import Foundation

// MARK: - APIErrorResponse

/// A generic structure for decoding server error response bodies.
/// Servers often return structured error information that can help with debugging
/// and user-facing error messages.
///
/// This struct is `nonisolated` because it's a pure data container used in networking
/// code that runs off the main actor.
nonisolated struct APIErrorResponse: Decodable, Equatable {
    // MARK: - Properties

    /// Error message from the server
    let message: String?

    /// Error code from the server (application-specific)
    let code: String?

    /// Detailed error description
    let details: String?

    /// Field-specific validation errors
    let errors: [String: [String]]?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case message
        case code
        case details
        case errors
        // Common alternative keys
        case error
        case errorMessage = "error_message"
        case errorCode = "error_code"
        case errorDescription = "error_description"
    }

    // MARK: - Init

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try multiple common keys for message
        message = try container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .error)
            ?? container.decodeIfPresent(String.self, forKey: .errorMessage)

        // Try multiple common keys for code
        code = try container.decodeIfPresent(String.self, forKey: .code)
            ?? container.decodeIfPresent(String.self, forKey: .errorCode)

        // Try multiple common keys for details
        details = try container.decodeIfPresent(String.self, forKey: .details)
            ?? container.decodeIfPresent(String.self, forKey: .errorDescription)

        errors = try container.decodeIfPresent([String: [String]].self, forKey: .errors)
    }

    /// Creates an APIErrorResponse with explicit values.
    init(message: String?, code: String? = nil, details: String? = nil, errors: [String: [String]]? = nil) {
        self.message = message
        self.code = code
        self.details = details
        self.errors = errors
    }
}

// MARK: - APIErrorResponse + CustomStringConvertible

nonisolated extension APIErrorResponse: CustomStringConvertible {
    var description: String {
        var parts: [String] = []

        if let code {
            parts.append("[\(code)]")
        }

        if let message {
            parts.append(message)
        }

        if let details {
            parts.append("Details: \(details)")
        }

        if let errors, !errors.isEmpty {
            let errorList = errors.map { "\($0.key): \($0.value.joined(separator: ", "))" }
            parts.append("Validation errors: \(errorList.joined(separator: "; "))")
        }

        return parts.isEmpty ? "Unknown error" : parts.joined(separator: " - ")
    }
}

// MARK: - APIErrorResponse + Parsing Helper

nonisolated extension APIErrorResponse {
    /// Attempts to decode an error response from data.
    /// Returns nil if decoding fails (data might not be a structured error).
    /// - Parameter data: The response data to decode
    /// - Returns: Decoded APIErrorResponse or nil
    static func decode(from data: Data?) -> APIErrorResponse? {
        guard let data, !data.isEmpty else { return nil }

        do {
            return try JSONDecoder().decode(APIErrorResponse.self, from: data)
        } catch {
            // If structured decoding fails, try to extract raw string as message
            if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
                return APIErrorResponse(message: rawString)
            }
            return nil
        }
    }
}
