//
//  NetworkManager.swift
//  Clothing Booth
//
//  Created by David Riegel on 28.04.25.
//

import Network
import Foundation

public final class NetworkManager {
    static let shared = NetworkManager()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private var timer: Timer?
    
    var isReachable: Bool = true
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied {
                Task { await self.checkServerReachable() }
            } else {
                DispatchQueue.main.async {
                    self.isReachable = false
                }
                stopServerReachablitityCheckTimer()
            }
        }
        
        monitor.start(queue: .main)
    }
    
    private func startServerReachabilityCheckTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task {
                await self?.checkServerReachable()
            }
        }
    }

    private func stopServerReachablitityCheckTimer() {
        timer?.invalidate()
        timer = nil
    }

    
    func checkServerReachable() async {
            do {
                try await pingServer()
                stopServerReachablitityCheckTimer()
                await MainActor.run {
                    self.isReachable = true
                }
            } catch {
                await MainActor.run {
                    startServerReachabilityCheckTimer()
                    self.isReachable = false
                }
            }
        }

    private func pingServer() async throws {
        var request = try await APIHandler.shared.createRequest(endpoint: "/ping", method: .GET, authentication: false)
        request.timeoutInterval = 5
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw APIError.offline
        }
    }
}
