import SwiftUI
import SpeedcheckerSDK
import CoreLocation

class SpeedTestManager: NSObject, ObservableObject, InternetSpeedTestDelegate {
    @Published var downloadSpeed: String = "0"
    @Published var uploadSpeed: String = "0"
    @Published var latency: String = "0"
    @Published var jitter: String = "0"
    @Published var isTestRunning: Bool = false
    
    private var internetTest: InternetSpeedTest?
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        
        DispatchQueue.global().async {
            guard CLLocationManager.locationServicesEnabled() else { return }
            DispatchQueue.main.async { [weak self] in
                self?.locationManager.requestWhenInUseAuthorization()
                self?.locationManager.requestAlwaysAuthorization()
            }
        }
    }
    
    func startSpeedTest() {
        isTestRunning = true
        internetTest = InternetSpeedTest(delegate: self)
        internetTest?.startFreeTest() { (error) in
            if error != .ok {
                print("Error: \(error.rawValue)")
            }
        }
    }
    
    // MARK: - InternetSpeedTestDelegate
    
    func internetTestError(error: SpeedTestError) {
        print("Error: \(error.rawValue)")
        isTestRunning = false
    }
    
    func internetTestFinish(result: SpeedTestResult) {
        DispatchQueue.main.async {
            self.downloadSpeed = String(format: "%.2f", result.downloadSpeed.mbps)
            self.uploadSpeed = String(format: "%.2f", result.uploadSpeed.mbps)
            self.latency = String(format: "%.0f", result.latencyInMs)
            self.isTestRunning = false
        }
    }
    
    func internetTestReceived(servers: [SpeedTestServer]) {}
    
    func internetTestSelected(server: SpeedTestServer, latency: Int, jitter: Int) {
        DispatchQueue.main.async {
            self.latency = "\(latency)"
            self.jitter = "\(jitter)"
        }
    }
    
    func internetTestDownloadStart() {}
    func internetTestDownloadFinish() {}
    
    func internetTestDownload(progress: Double, speed: SpeedTestSpeed) {
        DispatchQueue.main.async {
            self.downloadSpeed = speed.descriptionInMbps
        }
    }
    
    func internetTestUploadStart() {}
    func internetTestUploadFinish() {}
    
    func internetTestUpload(progress: Double, speed: SpeedTestSpeed) {
        DispatchQueue.main.async {
            self.uploadSpeed = speed.descriptionInMbps
        }
    }
}

extension SpeedTestManager: CLLocationManagerDelegate {}

struct SpeedTestView: View {
    @StateObject private var speedTestManager = SpeedTestManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Speed Test Results")
                .font(.title)
                .padding()
            
            Group {
                ResultRow(title: "Download", value: speedTestManager.downloadSpeed, unit: "Mbps")
                ResultRow(title: "Upload", value: speedTestManager.uploadSpeed, unit: "Mbps")
                ResultRow(title: "Latency", value: speedTestManager.latency, unit: "ms")
                ResultRow(title: "Jitter", value: speedTestManager.jitter, unit: "ms")
            }
            
            Button(action: {
                speedTestManager.startSpeedTest()
            }) {
                Text(speedTestManager.isTestRunning ? "Testing..." : "Start Speed Test")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(speedTestManager.isTestRunning ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(speedTestManager.isTestRunning)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .bold()
            Text(unit)
        }
        .padding(.horizontal)
    }
}
