//
//  TokenManager.swift
//  Wearhouse
//
//  Created by David Riegel on 24.09.25.
//

import Foundation

actor TokenManager {
    static let shared = TokenManager()
    private let account = "tokens"
    private let service = "com.wearhouse.auth"
    private var cachedTokens: TokenKeychainModel?
    
    func currentTokens() -> TokenKeychainModel? {
        if cachedTokens == nil {
            cachedTokens = loadFromKeychain()
        }
        return cachedTokens
    }
        
    func setTokens(_ tokens: TokenKeychainModel) {
        cachedTokens = tokens
        if let data = try? JSONEncoder().encode(tokens) {
            KeychainHelper.save(data, service: service, account: account)
        }
    }
        
    func clearTokens() {
        cachedTokens = nil
        KeychainHelper.delete(service: service, account: account)
    }
        
    private func loadFromKeychain() -> TokenKeychainModel? {
        guard let data = KeychainHelper.read(service: service, account: account),
              let tokens = try? JSONDecoder().decode(TokenKeychainModel.self, from: data) else {
            return nil
        }
        return tokens
    }
}
