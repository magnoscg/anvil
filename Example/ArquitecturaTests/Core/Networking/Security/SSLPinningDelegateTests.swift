import Foundation
import Security
import Testing
@testable import Arquitectura

// MARK: - SSLPinningDelegateTests

/// The expected pins were computed from each certificate with the command documented in
/// Production.xcconfig:
/// `openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`.
@Suite
struct SSLPinningDelegateTests {
    // MARK: - Pin Tests

    @Test("The pin of an RSA 2048 key matches the SubjectPublicKeyInfo hash from openssl")
    func rsa2048PinMatchesOpenSSL() throws {
        let key = try Self.publicKey(of: Self.rsa2048Certificate)

        #expect(SSLPinningDelegate.publicKeyPin(for: key) == "sha256/Qya+JIsBPbGeBJKAKJG7xE8oTc30ILiySBKJ4pGz/g8=")
    }

    @Test("The pin of an EC P-256 key matches the SubjectPublicKeyInfo hash from openssl")
    func ellipticCurveP256PinMatchesOpenSSL() throws {
        let key = try Self.publicKey(of: Self.p256Certificate)

        #expect(SSLPinningDelegate.publicKeyPin(for: key) == Self.p256Pin)
    }

    @Test("The pin of an EC P-384 key matches the SubjectPublicKeyInfo hash from openssl")
    func ellipticCurveP384PinMatchesOpenSSL() throws {
        let key = try Self.publicKey(of: Self.p384Certificate)

        #expect(SSLPinningDelegate.publicKeyPin(for: key) == "sha256/dqgJKXodWLPPu/gepFgJWBvteuUdR0L1ytsQLsyuhJM=")
    }

    @Test("The pin of an RSA 1024 key matches the SubjectPublicKeyInfo hash from openssl")
    func rsa1024PinMatchesOpenSSL() throws {
        let key = try Self.publicKey(of: Self.rsa1024Certificate)

        #expect(SSLPinningDelegate.publicKeyPin(for: key) == "sha256/nsGKAao6/urYqItwlyKY8DbhO29efit5/rqc39Zgsts=")
    }

    @Test("The pin of an RSA key with exponent 3 matches the SubjectPublicKeyInfo hash from openssl")
    func rsaExponentThreePinMatchesOpenSSL() throws {
        let key = try Self.publicKey(of: Self.rsa2048ExponentThreeCertificate)

        #expect(SSLPinningDelegate.publicKeyPin(for: key) == "sha256/EwuMUg/k0QU9bmbbbtjC/SFEoFxjfJAgT28YQvYusM4=")
    }

    @Test("The pins of a trust start with its leaf certificate")
    func trustPinsStartWithLeaf() throws {
        let certificate = try Self.certificate(of: Self.p256Certificate)
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
        let serverTrust = try #require(trust)

        #expect(status == errSecSuccess)
        #expect(SSLPinningDelegate.publicKeyPins(in: serverTrust).first == Self.p256Pin)
    }

    // MARK: - Pin Format Tests

    @Test("A sha256 pin of a 32-byte digest is valid")
    func digestPinIsValid() {
        #expect(SSLPinningDelegate.isValidPin(Self.p256Pin))
    }

    @Test("Placeholders, truncated pins and pins without the prefix are invalid",
          arguments: ["sha256/REPLACE_WITH_YOUR_PRODUCTION_CERTIFICATE_HASH=",
                      "sha256/3vIDjxskFtq6dc",
                      "3vIDjxskFtq6dc/Typn71SiUYMhzEKL5UjYAu1WBcgs=",
                      "sha256/"])
    func malformedPinIsInvalid(pin: String) {
        #expect(!SSLPinningDelegate.isValidPin(pin))
    }

    // MARK: - Chain Decision Tests

    @Test("A chain is accepted when any of its keys is pinned")
    func chainWithPinnedIntermediateIsAccepted() {
        let delegate = SSLPinningDelegate(publicKeyHashes: ["sha256/intermediate"], pinnedHosts: [Self.apiHost])

        #expect(delegate.acceptsChain(withPins: ["sha256/leaf", "sha256/intermediate"]))
        #expect(!delegate.acceptsChain(withPins: ["sha256/leaf"]))
    }

    @Test("Without pins every chain is rejected")
    func emptyPinSetRejectsEveryChain() {
        let delegate = SSLPinningDelegate(publicKeyHashes: [], pinnedHosts: [Self.apiHost])

        #expect(!delegate.acceptsChain(withPins: [Self.p256Pin]))
    }

    // MARK: - Challenge Handling Tests

    @Test("A host without pins gets the default handling")
    func unpinnedHostGetsDefaultHandling() async {
        let delegate = SSLPinningDelegate(publicKeyHashes: [Self.p256Pin], pinnedHosts: [Self.apiHost])
        let challenge = Self.makeChallenge(host: "pokeapi.co", method: NSURLAuthenticationMethodServerTrust)

        let (disposition, credential) = await delegate.urlSession(URLSession.shared, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    @Test("A pinned host without a server trust is rejected, whatever the host's case")
    func pinnedHostWithoutTrustIsRejected() async {
        let delegate = SSLPinningDelegate(publicKeyHashes: [Self.p256Pin], pinnedHosts: [Self.apiHost])
        let challenge = Self.makeChallenge(host: "API.Example.com", method: NSURLAuthenticationMethodServerTrust)

        let (disposition, _) = await delegate.urlSession(URLSession.shared, didReceive: challenge)

        #expect(disposition == .cancelAuthenticationChallenge)
    }

    @Test("Challenges other than server trust get the default handling")
    func otherChallengesGetDefaultHandling() async {
        let delegate = SSLPinningDelegate(publicKeyHashes: [Self.p256Pin], pinnedHosts: [Self.apiHost])
        let challenge = Self.makeChallenge(host: Self.apiHost, method: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, _) = await delegate.urlSession(URLSession.shared, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
    }

    // MARK: - Helpers

    private static let apiHost = "api.example.com"
    private static let p256Pin = "sha256/3vIDjxskFtq6dc/Typn71SiUYMhzEKL5UjYAu1WBcgs="

    private static func certificate(of base64Lines: [String]) throws -> SecCertificate {
        let data = try #require(Data(base64Encoded: base64Lines.joined()))
        return try #require(SecCertificateCreateWithData(nil, data as CFData))
    }

    private static func publicKey(of base64Lines: [String]) throws -> SecKey {
        try #require(SecCertificateCopyKey(certificate(of: base64Lines)))
    }

    private static func makeChallenge(host: String, method: String) -> URLAuthenticationChallenge {
        let protectionSpace = URLProtectionSpace(host: host,
                                                 port: 443,
                                                 protocol: NSURLProtectionSpaceHTTPS,
                                                 realm: nil,
                                                 authenticationMethod: method)
        return URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                          proposedCredential: nil,
                                          previousFailureCount: 0,
                                          failureResponse: nil,
                                          error: nil,
                                          sender: IgnoringChallengeSender())
    }

    // MARK: - Certificates

    private static let rsa2048Certificate = ["MIIDHzCCAgegAwIBAgIUar/hnRAwdhpCO71m8LBcZlUzR2EwDQYJKoZIhvcNAQELBQAw",
                                             "HzEdMBsGA1UEAwwUcGlubmluZy10ZXN0LXJzYTIwNDgwHhcNMjYxMTAzMTUwMjExWhcN",
                                             "MzYxMDMxMTUwMjExWjAfMR0wGwYDVQQDDBRwaW5uaW5nLXRlc3QtcnNhMjA0ODCCASIw",
                                             "DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfZnk9fvjgC2v+CW+gIkNjuqWqpa0Kj",
                                             "IxZvBtQl40jYJxWC53EtmgUXYmdyhhDSL0OkQcJOTrMpFhrOiTiFkvkdfpz+Xfyul/FK",
                                             "b4+alvLXpfPRwgsV53RBYDL1qJqXI5kiaozTGsgihNF5nVV830SAEsb8gcaYkC/KtK0x",
                                             "/QSJw0A0LYet9cdwtAKh12W0fX47wUdzkf7HbhCF4cXvbP4O94PXUP1hHR6DYSlEBOp2",
                                             "Gwjm2nisU+AnXYYdSKIw/kIYe02fcUi0YL2UjHfgsuIoqEd7OWAGxEG9O5rbuwt3FCWS",
                                             "JC1AJCWaKKuZlLMCP87eLxmeJ5Y89NysSPajY08CAwEAAaNTMFEwHQYDVR0OBBYEFIY0",
                                             "U3441rg0udyEvAk/e/lOk8tsMB8GA1UdIwQYMBaAFIY0U3441rg0udyEvAk/e/lOk8ts",
                                             "MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBACYFHjw7kUR1XzvtYNF4",
                                             "Ao+uv6xb3LE2XENtXgWxJZhfJ+FzJuJMo4AiMtgK0m2uQVS8wYb89ue8gHerB3wf7Ss7",
                                             "6gMP3H822bx62lZNeo5WfxyQi3DuGiv/ZSCeBIIaVfxQwEr5d3l7VtkkqYATaDxaHHK9",
                                             "Kt+W6GHxYeNoEL4djByDBG7VBOoNliqWTT+rpUf3Xt7SUx0MWg4fcqwyYIJdDjIWhPyx",
                                             "7hTR54lllXKcE/dLHDtshwDduahX0uqwEMxDO6XwrjRIODaH/hAnNsF5kgenlS1NCUZy",
                                             "Wfwvmp2D17hlXt5xCUWJHIP4tl1NaFjRIH5/EqMe4GZgbeUrhIo="]

    private static let p256Certificate = ["MIIBjTCCATOgAwIBAgIUZ1XHZ/Kyu4UE9gFi/dWrfdlyr00wCgYIKoZIzj0EAwIwHDEaMBg",
                                          "GA1UEAwwRcGlubmluZy10ZXN0LXAyNTYwHhcNMjYxMTAzMTUwMjE0WhcNMzYxMDMxMTUwMj",
                                          "E0WjAcMRowGAYDVQQDDBFwaW5uaW5nLXRlc3QtcDI1NjBZMBMGByqGSM49AgEGCCqGSM49A",
                                          "wEHA0IABAMeIMlxoaivdXago+XWhLBCSaFX0pcrX+dLWisQTu7RxCXHZXf78HfmKkCdv42Y",
                                          "2E9zDYzTsTwZB2/ltHgkgvKjUzBRMB0GA1UdDgQWBBQUHs++E6iSLnxExcCaLFrGzXQtMjA",
                                          "fBgNVHSMEGDAWgBQUHs++E6iSLnxExcCaLFrGzXQtMjAPBgNVHRMBAf8EBTADAQH/MAoGCC",
                                          "qGSM49BAMCA0gAMEUCIQCDf9i0qj8X18/pzrCZqlqygmWv8Dr9cyCToQjU8l3CEgIgBaDKW",
                                          "ULPsClpMg6HgzrA292dnqUL8vTU+i5HCBPRhb4="]

    private static let p384Certificate = ["MIIByTCCAVCgAwIBAgIUWzw3Z8rmGTVKAB4HkP967eINJKowCgYIKoZIzj0EAwIwHDEaMBg",
                                          "GA1UEAwwRcGlubmluZy10ZXN0LXAzODQwHhcNMjYxMTAzMTUwMjE0WhcNMzYxMDMxMTUwMj",
                                          "E0WjAcMRowGAYDVQQDDBFwaW5uaW5nLXRlc3QtcDM4NDB2MBAGByqGSM49AgEGBSuBBAAiA",
                                          "2IABFmDRgCRjzbdcgGA+YPb8esZHWCzoMfNr9oYaVp8dnq75Hdxv5OIeYy+CHyqKowJdDk/",
                                          "wdlg18IHPGCenHxj6poPy5K2mcHrFZskaYp8FA1+9kmEVgrIXZuP+P8Vi+Q1DqNTMFEwHQY",
                                          "DVR0OBBYEFDArFgRthFdM8yMJSc5VZjW4eAi6MB8GA1UdIwQYMBaAFDArFgRthFdM8yMJSc",
                                          "5VZjW4eAi6MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDZwAwZAIwNJRVVNOvpgxip",
                                          "IbsNiVuhQ95VaOmOn+GzYPoC3yxxVlfEYlr30qDZiX25mA8AcOJAjBCQIcBxuWi6NRXn7+O",
                                          "GiLBDMUFobPz1iLRdqn+7ibO+hDnLfC+PACmU/IzuXXX5ZU="]

    private static let rsa2048ExponentThreeCertificate = ["MIIDIzCCAgugAwIBAgIUYvyIFfBtvU5lUPlz36PTaImUd8wwDQYJKoZ",
                                                          "IhvcNAQELBQAwIjEgMB4GA1UEAwwXcGlubmluZy10ZXN0LXJzYTIwND",
                                                          "gtZTMwHhcNMjYxMTAzMTUyMzMyWhcNMzYxMDMxMTUyMzMyWjAiMSAwH",
                                                          "gYDVQQDDBdwaW5uaW5nLXRlc3QtcnNhMjA0OC1lMzCCASAwDQYJKoZI",
                                                          "hvcNAQEBBQADggENADCCAQgCggEBALGl5LS4TrB+LeGnBXSEruKcUB1",
                                                          "dhku3IvRi7ijocMWxvJNM+1E8n7LHkEsyT9cA30GTLsLsWtYWbcs6Ze",
                                                          "KrmazcpRx2lVy2sZp8VAtyEZdjB7PpkRROMxNInCgWihJAaFUohj67G",
                                                          "o4n/eFJgqR8iveEZWRuUmFFjdjxvhyrvN/8HdgeUqeX4oEuLswV2PG1",
                                                          "Kzh1kj5dzt4FzkGNWzF9uE0EQ6HcUXKNjjLzuSu25MxpTGoxZtdWzb3",
                                                          "Td5VZmVzKanwP4/Cn8hmzCppH2N4d1qr6Imywf6vtEXX1dFhc+eD4EP",
                                                          "60WZxWSoWV0DbV29P/KhdK+0UACF9CfFAUaUdfP7kCAQOjUzBRMB0GA",
                                                          "1UdDgQWBBTMWHZe+9WI8WAdppWT6bFi5cmsuDAfBgNVHSMEGDAWgBTM",
                                                          "WHZe+9WI8WAdppWT6bFi5cmsuDAPBgNVHRMBAf8EBTADAQH/MA0GCSq",
                                                          "GSIb3DQEBCwUAA4IBAQB1c7ynxPTCtkU1v+j+AhBfTtMDWOnk+jw3VY",
                                                          "GF2iU2SdUNwODK97ZoLU81/44B8HbKIErSMsfmaZlL1jVrtXFCFo/6R",
                                                          "mTPFSyAQYXbLO6fPFS2fecXANJ2a7Wr1FJTqVeboJ/ltEZth2a5nYS7",
                                                          "8BYMxbM/TH1vAriWK28dI0CywYIE4aUIvMx8RHHzZl/oqiE4bjeSG7l",
                                                          "9dL+1wI3dGTWQ7+ZgXRePBmIeJ395n0sDqD0rYL5LKOWSDZZDGZgAgC",
                                                          "VDwht9XDs038gZ/W/2wzJ1BjGSun3k40FYqmB8YdpwIgFJVtB0xGMiQ",
                                                          "6dbc0dh7sy7DLYOXeepbnBCggr9OWB6"]

    private static let rsa1024Certificate = ["MIICGjCCAYOgAwIBAgIUGKpG3v79HCcgBhwfF5wXB7CP1pMwDQYJKoZIhvcNAQELBQAw",
                                             "HzEdMBsGA1UEAwwUcGlubmluZy10ZXN0LXJzYTEwMjQwHhcNMjYxMTAzMTUwMjE0WhcN",
                                             "MzYxMDMxMTUwMjE0WjAfMR0wGwYDVQQDDBRwaW5uaW5nLXRlc3QtcnNhMTAyNDCBnzAN",
                                             "BgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAq1+GITNxM3A4yHse/MpixR0Sv3Vapa2fS/2E",
                                             "VZPDnug7iQK95yLdglAPEx2uZX0H6TEutiJ+5xssCutxPF9W6fKGQKw1oclfFzEleZmD",
                                             "2XRtsanVyjdjwPiosPV/smXIOZN9s4iqCbj4tZeN59OKFPym4n9e7uP0P3CCMtHvrn8C",
                                             "AwEAAaNTMFEwHQYDVR0OBBYEFInCs3xUg/xq8+M9WnyEohvporV1MB8GA1UdIwQYMBaA",
                                             "FInCs3xUg/xq8+M9WnyEohvporV1MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL",
                                             "BQADgYEAIbcqDgMH7w/s/PpSjUUp45u/jgmQOi7Pcck7r5puTffCN7U5K8gx7LBaU2DK",
                                             "J9+EjpjdaveFd2hnIpTnaQgTOoLpOVsgydiWzmuyflNt9SK8p9bCWmalEoBjpQhRmP4E",
                                             "7RRbq5jmNKczOtRn76ebV3xjXFO44rsDBHCzcnIWz7w="]
}

// MARK: - IgnoringChallengeSender

/// Challenge sender that ignores every call: the delegate under test returns its decision instead.
private final nonisolated class IgnoringChallengeSender: NSObject, URLAuthenticationChallengeSender {
    // MARK: - URLAuthenticationChallengeSender

    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
