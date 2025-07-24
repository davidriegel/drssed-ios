//
//  NetworkManager.swift
//  Clothing Booth
//
//  Created by David Riegel on 28.04.25.
//

import Network

public final class NetworkManager {
    static let shared = NetworkManager()
    private let monitor = NWPathMonitor()
    
    var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
    }
}
