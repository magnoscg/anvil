import CryptoKit
import Foundation
import Security

// MARK: - SSLPinningDelegate

/// URLSessionDelegate that implements SSL Public Key Pinning.
/// Validates server certificates against a list of known public key hashes.
///
/// Thread Safety: Conforms to `Sendable` via `@unchecked` because:
/// - All stored properties are immutable (`let` constants)
/// - URLSessionDelegate methods are called from arbitrary URLSession threads
/// - `extractPublicKeyHash(_:)` is a pure function with no shared mutable state
///
/// - Warning: DO NOT add mutable (`var`) properties to this class without re-analyzing
///   thread safety. Any shared mutable state requires proper synchronization.
final class SSLPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    // MARK: - Properties

    private let pinnedPublicKeyHashes: [String]
    private let isEnabled: Bool

    // MARK: - Init

    /// Creates an SSL Pinning delegate.
    /// - Parameters:
    ///   - publicKeyHashes: Array of base64-encoded SHA256 hashes of public keys (format: "sha256/...")
    ///   - isEnabled: Whether pinning validation is enabled. When false, default handling is used.
    init(publicKeyHashes: [String], isEnabled: Bool = true) {
        self.pinnedPublicKeyHashes = publicKeyHashes
        self.isEnabled = isEnabled
        super.init()
    }

    // MARK: - URLSessionDelegate

    nonisolated func urlSession(_ session: URLSession,
                                didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        // If pinning is disabled, use default handling
        guard isEnabled else {
            return (.performDefaultHandling, nil)
        }

        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }

        // Validate certificate chain
        let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
        SecTrustSetPolicies(serverTrust, policies as CFArray)

        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            return (.cancelAuthenticationChallenge, nil)
        }

        // Extract and validate public key hash
        guard let publicKeyHash = extractPublicKeyHash(from: serverTrust) else {
            return (.cancelAuthenticationChallenge, nil)
        }

        // Check if the hash matches any of the pinned hashes
        if pinnedPublicKeyHashes.contains(publicKeyHash) {
            let credential = URLCredential(trust: serverTrust)
            return (.useCredential, credential)
        }

        // Hash doesn't match - reject the connection
        return (.cancelAuthenticationChallenge, nil)
    }

    // MARK: - Private Methods

    /// Extracts the SHA256 hash of the server's public key.
    /// - Parameter trust: The server trust object from the authentication challenge.
    /// - Returns: Base64-encoded SHA256 hash prefixed with "sha256/", or nil if extraction fails.
    private func extractPublicKeyHash(from trust: SecTrust) -> String? {
        // Get certificate chain
        guard let certificates = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let certificate = certificates.first else {
            return nil
        }

        // Extract public key from certificate
        guard let publicKey = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        // Compute SHA256 hash of the public key
        let hash = SHA256.hash(data: publicKeyData)
        let hashData = Data(hash)

        return "sha256/" + hashData.base64EncodedString()
    }
}

// MARK: - SSLPinningError

/// Errors that can occur during SSL pinning validation.
enum SSLPinningError: Error, LocalizedError {
    case invalidCertificate
    case publicKeyExtractionFailed
    case hashMismatch

    var errorDescription: String? {
        switch self {
        case .invalidCertificate:
            "Server certificate is invalid"
        case .publicKeyExtractionFailed:
            "Failed to extract public key from certificate"
        case .hashMismatch:
            "Server public key does not match pinned keys"
        }
    }
}
