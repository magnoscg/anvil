import Foundation
import Testing
@testable import Arquitectura

// MARK: - APIErrorTests

@Suite
struct APIErrorTests {
    // MARK: - Retryable Tests

    @Test("Network timeout error is retryable")
    func networkTimeoutIsRetryable() {
        let error = APIError.networkError(URLError(.timedOut))
        #expect(error.isRetryable == true)
    }

    @Test("Network connection lost is retryable")
    func networkConnectionLostIsRetryable() {
        let error = APIError.networkError(URLError(.networkConnectionLost))
        #expect(error.isRetryable == true)
    }

    @Test("Not connected to internet is retryable")
    func notConnectedIsRetryable() {
        let error = APIError.networkError(URLError(.notConnectedToInternet))
        #expect(error.isRetryable == true)
    }

    @Test("Server error 500 is retryable")
    func serverError500IsRetryable() {
        let error = APIError.httpError(statusCode: 500, data: nil)
        #expect(error.isRetryable == true)
    }

    @Test("Rate limiting 429 is retryable")
    func rateLimiting429IsRetryable() {
        let error = APIError.httpError(statusCode: 429, data: nil)
        #expect(error.isRetryable == true)
    }

    @Test("Client error 404 is not retryable")
    func clientError404IsNotRetryable() {
        let error = APIError.httpError(statusCode: 404, data: nil)
        #expect(error.isRetryable == false)
    }

    @Test("Client error 401 is not retryable")
    func clientError401IsNotRetryable() {
        let error = APIError.httpError(statusCode: 401, data: nil)
        #expect(error.isRetryable == false)
    }

    @Test("Decoding error is not retryable")
    func decodingErrorIsNotRetryable() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "test")
        let error = APIError.decodingError(.dataCorrupted(context))
        #expect(error.isRetryable == false)
    }

    @Test("Invalid URL is not retryable")
    func invalidURLIsNotRetryable() {
        let error = APIError.invalidURL
        #expect(error.isRetryable == false)
    }

    @Test("Unknown error is not retryable")
    func unknownErrorIsNotRetryable() {
        let error = APIError.unknown(SendableError(NSError(domain: "test", code: 1)))
        #expect(error.isRetryable == false)
    }

    // MARK: - Error Description Tests

    @Test("Network error has localized description")
    func networkErrorDescription() {
        let error = APIError.networkError(URLError(.timedOut))
        #expect(error.errorDescription != nil)
    }

    @Test("HTTP error description contains status code")
    func httpErrorDescription() {
        let error = APIError.httpError(statusCode: 503, data: nil)
        #expect(error.errorDescription?.contains("503") == true)
    }

    @Test("Invalid URL description is correct")
    func invalidURLDescription() {
        let error = APIError.invalidURL
        #expect(error.errorDescription == "Invalid URL")
    }

    // MARK: - Server Error Extraction

    @Test("serverError decodes valid JSON error response")
    func serverErrorDecodesValidJSON() {
        let json = """
        {"message": "Not Found", "code": "NOT_FOUND"}
        """.data(using: .utf8)

        let error = APIError.httpError(statusCode: 404, data: json)
        let serverError = error.serverError

        #expect(serverError?.message == "Not Found")
        #expect(serverError?.code == "NOT_FOUND")
    }

    @Test("serverError returns nil for non-HTTP errors")
    func serverErrorReturnsNilForNonHTTPErrors() {
        let error = APIError.invalidURL
        #expect(error.serverError == nil)
    }

    @Test("serverError returns nil for nil data")
    func serverErrorReturnsNilForNilData() {
        let error = APIError.httpError(statusCode: 500, data: nil)
        #expect(error.serverError == nil)
    }
}

// MARK: - APIErrorResponseTests

@Suite
struct APIErrorResponseTests {
    @Test("Decodes standard error response")
    func decodesStandardResponse() throws {
        let json = """
        {"message": "Bad Request", "code": "INVALID_PARAMS", "details": "Missing name field"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIErrorResponse.self, from: json)

        #expect(response.message == "Bad Request")
        #expect(response.code == "INVALID_PARAMS")
        #expect(response.details == "Missing name field")
    }

    @Test("Decodes alternative key names")
    func decodesAlternativeKeys() throws {
        let json = """
        {"error": "Unauthorized", "error_code": "AUTH_FAILED"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIErrorResponse.self, from: json)

        #expect(response.message == "Unauthorized")
        #expect(response.code == "AUTH_FAILED")
    }

    @Test("decode returns nil for empty data")
    func decodeReturnsNilForEmptyData() {
        #expect(APIErrorResponse.decode(from: nil) == nil)
        #expect(APIErrorResponse.decode(from: Data()) == nil)
    }

    @Test("decode falls back to raw string for invalid JSON")
    func decodeFallsBackToRawString() {
        let data = "Something went wrong".data(using: .utf8)
        let response = APIErrorResponse.decode(from: data)

        #expect(response?.message == "Something went wrong")
    }

    @Test("description formats all fields")
    func descriptionFormatsAllFields() {
        let response = APIErrorResponse(message: "Error",
                                        code: "ERR_001",
                                        details: "Something failed")

        let desc = response.description
        #expect(desc.contains("[ERR_001]"))
        #expect(desc.contains("Error"))
        #expect(desc.contains("Something failed"))
    }

    @Test("description returns 'Unknown error' when all fields nil")
    func descriptionWithAllNilFields() {
        let response = APIErrorResponse(message: nil)
        #expect(response.description == "Unknown error")
    }
}
