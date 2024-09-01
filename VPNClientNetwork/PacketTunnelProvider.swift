import NetworkExtension
import OpenVPNAdapter

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // Handlers
    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    
    // VPN-related properties
    var vpnReachability = OpenVPNReachability()
    var vpnConfiguration: OpenVPNConfiguration!
    var vpnProperties: OpenVPNProperties!
    
    // Network sessions
    var udpSession: NWUDPSession!
    var tcpConnection: NWTCPConnection!
    
    // Lazy-loaded VPN adapter with delegate set
    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()
    
    // Start the VPN tunnel
    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        print("VPN startTunnel")
        guard
            let protocolConfig = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfig = protocolConfig.providerConfiguration,
            let ovpnFileContent = providerConfig["ovpn"] as? Data
        else {
            fatalError("Invalid or missing configuration.")
        }
        
        // Configure OpenVPN
        vpnConfiguration = OpenVPNConfiguration()
        vpnConfiguration.fileContent = ovpnFileContent
        vpnConfiguration.tunPersist = true
        
        do {
            vpnProperties = try vpnAdapter.apply(configuration: vpnConfiguration)
        } catch {
            completionHandler(error)
            return
        }
        
        // Handle autologin
        if !vpnProperties.autologin,
           let username = providerConfig["username"] as? String,
           let password = providerConfig["password"] as? String {
            let credentials = OpenVPNCredentials()
            credentials.username = username
            credentials.password = password
            do {
                try vpnAdapter.provide(credentials: credentials)
            } catch {
                completionHandler(error)
                return
            }
        }
        
        // Start VPN reachability tracking
        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }
        
        // Start VPN connection
        startHandler = completionHandler
        vpnAdapter.connect()
    }
    
    // Stop the VPN tunnel
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler
        
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        
        vpnAdapter.disconnect()
    }
    
    // Handle app messages
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        completionHandler?(messageData)
    }
    
    // Handle sleep and wake states
    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func wake() {
        // Handle wake if needed
    }
}

// MARK: - OpenVPNAdapterDelegate

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    
    // Configure the VPN tunnel with network settings
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        setTunnelNetworkSettings(networkSettings) { error in
            completionHandler(error == nil ? self.packetFlow : nil)
        }
    }

    // Handle VPN events
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            startHandler?(nil)
            startHandler = nil
            NSLog("VPN Connected")
            
        case .disconnected:
            stopVPNTrackingAndHandleDisconnection()
            NSLog("VPN Disconnected")
            
        case .reconnecting:
            reasserting = true
            NSLog("VPN Reconnecting")
            
        default:
            break
        }
    }
    
    // Handle errors from the VPN adapter
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        let isFatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool ?? false
        
        if isFatal {
            NSLog("Fatal error: \(error.localizedDescription)")
            NSLog("Connection Info: \(vpnAdapter.connectionInformation.debugDescription)")
            stopVPNTrackingAndHandleDisconnection()
            startHandler?(error)
            startHandler = nil
        } else {
            NSLog("Error: \(error.localizedDescription)")
        }
    }
    
    // Log VPN adapter messages
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        NSLog("Log: \(logMessage)")
    }
    
    // Stop VPN tracking and handle disconnection
    private func stopVPNTrackingAndHandleDisconnection() {
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        stopHandler?()
        stopHandler = nil
    }
}

// MARK: - OpenVPNAdapterPacketFlow

extension PacketTunnelProvider: OpenVPNAdapterPacketFlow {
    
    func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
        packetFlow.readPackets(completionHandler: completionHandler)
    }
    
    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        return packetFlow.writePackets(packets, withProtocols: protocols)
    }
}

// MARK: - NEPacketTunnelFlow Extension

extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}
