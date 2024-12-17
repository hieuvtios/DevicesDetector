//
//  ContentView2.swift
//  CameraIP
//
//  Created by Hieu Vu on 17/12/24.
//

import Foundation
import Network
import Combine
import SystemConfiguration.CaptiveNetwork
import SwiftUI




struct ScanViaWifiView: View {
    @StateObject private var networkScanner = NetworkScanner()
    var body: some View {
        NavigationView {
            VStack {
                // Scanning Controls
                HStack {
                    Button(action: {
                        networkScanner.startScanning()
                    }) {
                        Text("Start Scanning")
                            .foregroundColor(.white)
                            .padding()
                            .background(networkScanner.isScanning ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(networkScanner.isScanning)
                    
                    Button(action: {
                        networkScanner.stopScanning()
                    }) {
                        Text("Stop Scanning")
                            .foregroundColor(.white)
                            .padding()
                            .background(networkScanner.isScanning ? Color.red : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!networkScanner.isScanning)
                }
                .padding()
                
                // Scanning Status
                if networkScanner.isScanning {
                    ProgressView("Scanning...")
                        .padding()
                }
                
                // List of Discovered Devices
                List(networkScanner.discoveredDevices) { device in
                    VStack(alignment: .leading) {
                        Text(device.ipAddress)
                            .font(.headline)
                        if let name = device.deviceName {
                            Text(name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text("Open Ports: \(device.openPorts.map { "\($0)" }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Network Scanner")
        }
        .onAppear {
            // Optionally start scanning automatically
            // networkScanner.startScanning()
        }
    }
}
