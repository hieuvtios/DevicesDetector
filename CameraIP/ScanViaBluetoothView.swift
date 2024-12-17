//
//  ScanViaBluetoothView.swift
//  CameraIP
//
//  Created by Hieu Vu on 17/12/24.

import SwiftUI
import CoreBluetooth

struct ScanViaBluetoothView: View {
    @StateObject var bluetoothScanner = BluetoothScanner()
    
    var body: some View {
        NavigationView {
            VStack {
                // Discovered Devices Section
                Section(header: Text("Discovered Devices").font(.headline).padding()) {
                    List(bluetoothScanner.discoveredDevices, id: \.identifier) { device in
                        HStack {
                            if(device.name?.count ?? 0 > 0){
                                Text(device.name ?? "Unknown Device")
                                Spacer()
                            }
                        }
                        .frame(height: 50)
                    }
                }
            }
            .navigationTitle("Bluetooth Scanner")
        }
    }
}
#Preview {
    ScanViaBluetoothView()
}
