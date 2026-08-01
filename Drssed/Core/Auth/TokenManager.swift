//
//  TokenManager.swift
//  Drssed
//
//  Created by David Riegel on 24.09.25.
//

import Foundation

actor TokenManager {
    static let shared = TokenManager()
    private let account = "tokens"
    private let service = "com.drssed.auth"
    private var cachedTokens: TokenKeychainModel?

    private var refreshTask: Task<TokenKeychainModel, Error>?

    func currentTokens() -> TokenKeychainModel? {
        if cachedTokens == nil {
            cachedTokens = loadFromKeychain()
        }
        return cachedTokens
    }

    func validAccessToken(forceRefresh: Bool = false) async throws -> String {
        guard let tokens = currentTokens() else { throw AuthenticationError.userNotSignedIn }

        guard forceRefresh || tokens.willExpireSoon else { return tokens.accessToken }

        return try await refresh(using: tokens.refreshToken).accessToken
    }

    func setTokens(_ tokens: TokenKeychainModel) {
        cachedTokens = tokens
        if let data = try? JSONEncoder().encode(tokens) {
            KeychainHelper.save(data, service: service, account: account)
        }
    }

    func clearTokens() {
        refreshTask?.cancel()
        refreshTask = nil
        cachedTokens = nil
        KeychainHelper.delete(service: service, account: account)
    }

    private func refresh(using refreshToken: String) async throws -> TokenKeychainModel {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task<TokenKeychainModel, Error> {
            let response = try await APIClient.shared.authHandler.performTokenRefresh(refreshToken: refreshToken)
            let renewed = try TokenKeychainModel(from: response)

            try Task.checkCancellation()

            self.setTokens(renewed)

            return renewed
        }

        refreshTask = task
        defer { refreshTask = nil }

        return try await task.value
    }

    private func loadFromKeychain() -> TokenKeychainModel? {
        guard let data = KeychainHelper.read(service: service, account: account),
              let tokens = try? JSONDecoder().decode(TokenKeychainModel.self, from: data) else {
            return nil
        }
        return tokens
    }
}
