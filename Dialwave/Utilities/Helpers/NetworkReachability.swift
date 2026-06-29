import Foundation
import Network
import Combine

/// Monitors local network connectivity and exposes the device's WiFi IP address.
///
/// Uses `NWPathMonitor` to reactively track WiFi availability. The discovered
/// local IP is used during Bluetooth handshake to tell Android where to connect.
@MainActor
final class NetworkReachability: ObservableObject {

    // MARK: - Published Properties

    /// Whether the device is currently connected to a WiFi network.
    @Published private(set) var isWiFiAvailable: Bool = false

    /// The device's local IPv4 address on the WiFi interface, if available.
    @Published private(set) var currentIP: String?

    /// Whether both the Mac and a hypothetical peer are reachable on the local network.
    @Published private(set) var isConnectedToSameNetwork: Bool = false

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.dialwave.network-monitor", qos: .utility)

    // MARK: - Init

    init() {
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    /// Begin observing network path changes on a background queue.
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wifi = path.usesInterfaceType(.wifi) && path.status == .satisfied
            let ip = wifi ? Self.fetchLocalIPAddress() : nil

            Task { @MainActor [weak self] in
                self?.isWiFiAvailable = wifi
                self?.currentIP = ip
                self?.isConnectedToSameNetwork = wifi && ip != nil

                if wifi {
                    AppLogger.info("WiFi connected — local IP: \(ip ?? "unknown")", category: .network)
                } else {
                    AppLogger.info("WiFi disconnected", category: .network)
                }
            }
        }
        monitor.start(queue: monitorQueue)
        AppLogger.debug("Network monitor started", category: .network)
    }

    // MARK: - IP Resolution

    /// Extracts the device's local IPv4 address from the `en0` (WiFi) interface
    /// using the POSIX `getifaddrs` API.
    /// - Returns: The IPv4 address string, or `nil` if unavailable.
    private static func fetchLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let interface = current.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            // Look for IPv4 on the WiFi interface (en0)
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let result = getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    if result == 0 {
                        address = String(cString: hostname)
                    }
                }
            }
            ptr = interface.ifa_next
        }

        return address
    }
}
