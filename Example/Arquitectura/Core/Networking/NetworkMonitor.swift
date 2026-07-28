import Foundation
import Network

// MARK: - NetworkMonitor

/// Protocol for monitoring network connectivity status.
/// All properties are @MainActor isolated for safe UI observation.
@MainActor
protocol NetworkMonitor: Sendable {
    /// Whether the device currently has network connectivity
    var isConnected: Bool { get }

    /// Whether the current connection is expensive (cellular, hotspot)
    var isExpensive: Bool { get }

    /// Whether the current connection is constrained (Low Data Mode)
    var isConstrained: Bool { get }

    /// The current connection type
    var connectionType: ConnectionType { get }
}

// MARK: - ConnectionType

/// Represents the type of network connection.
nonisolated enum ConnectionType: String {
    case wifi
    case cellular
    case wiredEthernet
    case loopback
    case other
    case none
}

// MARK: - NetworkMonitorImpl

/// Implementation of NetworkMonitor using NWPathMonitor.
/// @MainActor isolated — compiler enforces all mutations happen on the main actor.
@MainActor
@Observable
final class NetworkMonitorImpl: NetworkMonitor {
    // MARK: - Properties

    private(set) var isConnected: Bool = false
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false
    private(set) var connectionType: ConnectionType = .none

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue

    // MARK: - Init

    /// Creates a network monitor.
    /// - Parameter queue: The dispatch queue to receive updates on (default: dedicated queue)
    init(queue: DispatchQueue = DispatchQueue(label: "com.app.networkMonitor", qos: .utility)) {
        self.monitor = NWPathMonitor()
        self.queue = queue

        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private Methods

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(from: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(from path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        connectionType = determineConnectionType(from: path)
    }

    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            .wifi
        } else if path.usesInterfaceType(.cellular) {
            .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            .loopback
        } else if path.status == .satisfied {
            .other
        } else {
            .none
        }
    }
}
