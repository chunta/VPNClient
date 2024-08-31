import NetworkExtension
import UIKit

class ViewController: UIViewController {
    
    var providerManager: NETunnelProviderManager!
    
    private let vpnServerAddress = "127.0.0.1"
    private let vpnUsername = "uid"
    private let vpnPassword = "pw123"
    private let vpnConfigFileName = "test.ovpn"
    private let vpnProviderBundleIdentifier = "com.testopenvpn.tunnel"
    private let vpnProfileDescription = "Test-OpenVPN"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProviderManager { [weak self] in
            self?.configureVPN()
        }
    }
    
    func loadProviderManager(completion: @escaping () -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard error == nil else {
                print("Error loading provider manager: \(error!.localizedDescription)")
                return
            }
            self?.providerManager = managers?.first ?? NETunnelProviderManager()
            completion()
        }
    }
    
    func configureVPN() {
        guard let configData = readFile(path: vpnConfigFileName) else {
            print("Failed to read config file.")
            return
        }
        
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                print("Error loading preferences: \(error!.localizedDescription)")
                return
            }
            
            let tunnelProtocol = self?.createTunnelProtocol(configData: configData)
            self?.applyVPNConfiguration(tunnelProtocol: tunnelProtocol)
        }
    }
    
    private func createTunnelProtocol(configData: Data) -> NETunnelProviderProtocol {
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.serverAddress = vpnServerAddress
        tunnelProtocol.username = vpnUsername
        tunnelProtocol.providerBundleIdentifier = vpnProviderBundleIdentifier
        tunnelProtocol.providerConfiguration = ["ovpn": configData, "username": vpnUsername, "password": vpnPassword]
        tunnelProtocol.disconnectOnSleep = false
        return tunnelProtocol
    }
    
    private func applyVPNConfiguration(tunnelProtocol: NETunnelProviderProtocol?) {
        guard let tunnelProtocol = tunnelProtocol else { return }
        
        providerManager.protocolConfiguration = tunnelProtocol
        providerManager.localizedDescription = vpnProfileDescription
        providerManager.isEnabled = true
        
        providerManager.saveToPreferences { [weak self] error in
            guard error == nil else {
                print("Error saving preferences: \(error!.localizedDescription)")
                return
            }
            self?.startVPNTunnel()
        }
    }
    
    private func startVPNTunnel() {
        providerManager.loadFromPreferences { [weak self] error in
            guard error == nil else {
                print("Error loading preferences: \(error!.localizedDescription)")
                return
            }
            do {
                try self?.providerManager.connection.startVPNTunnel()
            } catch {
                print("Error starting VPN tunnel: \(error.localizedDescription)")
            }
        }
    }

    private func readFile(path: String) -> Data? {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent(path)
            return try Data(contentsOf: fileURL, options: .uncached)
        } catch {
            print("Error reading file at \(path): \(error.localizedDescription)")
            return nil
        }
    }
}
