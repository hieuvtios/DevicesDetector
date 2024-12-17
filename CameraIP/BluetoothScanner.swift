import Foundation
import CoreBluetooth

class BluetoothScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on, starting to scan...")
            startScanning()
        case .poweredOff:
            print("Bluetooth is powered off.")
            // Clear devices when Bluetooth is turned off
            discoveredDevices.removeAll()
            connectedDevices.removeAll()
        case .resetting, .unauthorized, .unsupported, .unknown:
            print("Bluetooth is not available.")
        @unknown default:
            break
        }
    }
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("Scanning for devices...")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("Stopped scanning for devices.")
    }
    

    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi: NSNumber) {
        // Safely unwrap the peripheral's name
        if let name = peripheral.name, name != "Unknown" {
            // Check if the peripheral is already in the discoveredDevices array
            if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredDevices.append(peripheral)
                print("Discovered device: \(name) at \(rssi) dBm")
            }
        }
    }
    
  
}
