//
//  NetworkScanner.swift
//  CameraIP
//
//  Created by Hieu Vu on 17/12/24.
//

import Foundation
import Network
import Combine
import SystemConfiguration.CaptiveNetwork
import SwiftUI

// NetworkScanner Class
struct DiscoveredDevice: Identifiable {
    let id = UUID()
    let ipAddress: String
    let deviceName: String?
    let openPorts: [Int]
}
class NetworkScanner: ObservableObject {
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var isScanning: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Function to start scanning
    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        discoveredDevices = []
        
        guard let subnet = getSubnet() else {
            print("Unable to determine subnet.")
            isScanning = false
            return
        }
        
        // Define the ports you want to scan, e.g., common camera ports
        let portsToScan = [80, 554, 8080, 8888]
        
        // Scan IPs in the subnet
        scanSubnet(subnet: subnet, ports: portsToScan)
    }
    
    // Function to stop scanning (optional)
    func stopScanning() {
        isScanning = false
        // Implement logic to cancel ongoing scans if needed
    }
    
    // Function to get the current subnet
    private func getSubnet() -> String? {
        var address: String?
        // Get list of all interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // Iterate through interfaces
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) { // IPv4
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Wi-Fi interface
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let ip = String(cString: hostname)
                    // Extract subnet, e.g., "192.168.1"
                    let components = ip.split(separator: ".")
                    if components.count == 4 {
                        return String(components[0..<3].joined(separator: "."))
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
    
    // Function to scan the subnet
    private func scanSubnet(subnet: String, ports: [Int]) {
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "networkScannerQueue", attributes: .concurrent)
        
        for i in 1...254 {
            if !isScanning { break }
            let ip = "\(subnet).\(i)"
            dispatchGroup.enter()
            queue.async {
                self.scanDevice(ipAddress: ip, ports: ports) { device in
                    if let device = device {
                        DispatchQueue.main.async {
                            if(device.deviceName?.count ?? 0 > 0 ){
                                self.discoveredDevices.append(device)
                            }
                        }
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isScanning = false
            print("Scanning completed.")
        }
    }
    
    // Function to scan a single device
    private func scanDevice(ipAddress: String, ports: [Int], completion: @escaping (DiscoveredDevice?) -> Void) {
        var openPorts: [Int] = []
        let portDispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "portScannerQueue", attributes: .concurrent)
        
        for port in ports {
            if !isScanning { break }
            portDispatchGroup.enter()
            checkPort(ip: ipAddress, port: port) { isOpen in
                if isOpen {
                    openPorts.append(port)
                }
                portDispatchGroup.leave()
            }
        }
        
        portDispatchGroup.notify(queue: queue) {
            if !openPorts.isEmpty {
                // Optionally, perform a reverse DNS lookup to get the device name
                let deviceName = self.getDeviceName(ipAddress: ipAddress)
                let device = DiscoveredDevice(ipAddress: ipAddress, deviceName: deviceName, openPorts: openPorts)
                completion(device)
            } else {
                completion(nil)
            }
        }
    }
    
    // Function to check if a port is open
    private func checkPort(ip: String, port: Int, completion: @escaping (Bool) -> Void) {
        // Check if the port number is within a valid range (1 to 65535)
        guard port > 0 && port <= 65535 else {
            completion(false)
            return
        }

        // Create an NWEndpoint.Port from the port integer value
        let nwPort = NWEndpoint.Port(rawValue: UInt16(port))

        // If the port is invalid (0 is reserved), return false
        guard let validPort = nwPort, validPort.rawValue != 0 else {
            completion(false)
            return
        }

        // Create the network connection
        let connection = NWConnection(host: NWEndpoint.Host(ip), port: validPort, using: .tcp)

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                completion(true)
                connection.cancel()
            case .failed(_), .cancelled:
                completion(false)
            default:
                break
            }
        }

        connection.start(queue: .global())
    }
    
    // Optional: Function to get device name via reverse DNS
    private func getDeviceName(ipAddress: String) -> String? {
        let host = NWEndpoint.Host(ipAddress)
        let port = NWEndpoint.Port(rawValue: 0)!
        let params = NWParameters()
        let queue = DispatchQueue(label: "reverseDNS")
        var deviceName: String? = nil
        
        let connection = NWConnection(host: host, port: port, using: params)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                deviceName = connection.currentPath?.remoteEndpoint?.debugDescription
                connection.cancel()
            case .failed(_), .cancelled:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: queue)
        
        // Wait for a short duration to get the device name
        Thread.sleep(forTimeInterval: 0.5)
        return deviceName
    }
}
