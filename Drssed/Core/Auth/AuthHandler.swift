//
//  AuthHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 16.01.25.
//

import Foundation
import UIKit
import JWTDecode

final class AuthHandler {
    
    init() {}
    
    // MARK: -- register as new guest
    
    public func registerAsGuest() async throws -> TokenAPIResponse {
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/guest", method: .POST, authentication: false)
        
        let (data, _) = try await APIClient.shared.executeRequest(request: request, ignoreError: [])
        
        let tokenResponse = try JSONDecoder().decode(TokenAPIResponse.self, from: data)
        return tokenResponse
    }
    
    // MARK: -- sign into existing account
    
    public func signInWith(username: String? = nil, email: String? = nil, password: String) async throws -> TokenAPIResponse {
        guard !(username?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) || !(email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else { throw AuthenticationError.missingCredentials }
        
        var dict: [String: String] = ["password": password]
        
        if let username = username {
            dict["username"] = username
        }
        if let email = email {
            dict["email"] = email
        }

        let uploadData = try JSONEncoder().encode(dict)
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/login", method: .POST, body: uploadData, authentication: false)
        let (data, _) = try await APIClient.shared.executeRequest(request: request)
        
        let tokenResponse = try JSONDecoder().decode(TokenAPIResponse.self, from: data)
        
        return tokenResponse
    }
    
    // MARK: -- upgrade account
    
    public func upgradeAccount(username: String? = nil, email: String? = nil, password: String, profilePicture: String) async throws -> UpgradeAccountResponse {
        guard !(username?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) || !(email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else { throw AuthenticationError.missingCredentials }
        
        var dict: [String: String] = ["password": password, "profile_picture": profilePicture]
        
        if let username = username {
            dict["username"] = username
        }
        if let email = email {
            dict["email"] = email
        }

        let uploadData = try JSONEncoder().encode(dict)
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/upgrade", method: .POST, body: uploadData, authentication: true)
        let upgradeResponse: UpgradeAccountResponse = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return upgradeResponse
    }
    
    // MARK: -- POST SEND VERIFICATION EMAIL
    
    public func sendVerificationEmail() async throws {
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/email/send-verification", method: .POST)
        let (_, _) = try await APIClient.shared.executeRequest(request: request)
        
        return
    }
    
    // MARK: -- GET ACCESS TOKEN
    
    public func getAndRenewAccessToken() async throws -> String {
        guard let tokens = await TokenManager.shared.currentTokens() else { throw AuthenticationError.userNotSignedIn }
        var accessToken = tokens.accessToken
        
        if tokens.willExpireSoon {
            let tokenResponse = try await performTokenRefresh(refreshToken: tokens.refreshToken)
            
            let keychainModel = try TokenKeychainModel(from: tokenResponse)
            await TokenManager.shared.setTokens(keychainModel)
            
            accessToken = tokenResponse.access_token
        }
        
        return accessToken
    }
    
    private func performTokenRefresh(refreshToken: String) async throws -> TokenAPIResponse {
        let uploadData = try JSONEncoder().encode(["refresh_token": refreshToken])
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/refresh", method: .POST, body: uploadData, authentication: false)
        
        let tokenResponse: TokenAPIResponse = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return tokenResponse
    }
    
    // MARK: - Invalidate refresh token
    
    public func invalidateRefreshToken(refreshToken: String) async throws {
        let uploadData = try JSONEncoder().encode(["refresh_token": refreshToken])
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/logout", method: .POST, body: uploadData, authentication: false)
        
        let (_, _) = try await APIClient.shared.executeRequest(request: request)
    }
    
    // MARK: - Delete account
    
    public func deleteAccount() async throws {
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me", method: .DELETE, authentication: true)
        
        let (_, _) = try await APIClient.shared.executeRequest(request: request)
    }
    
    // MARK: -- Handler specific functions
    
    private func mapConflictsError(data: Data) throws -> AuthenticationError {
        let fetchError = try JSONDecoder().decode(ConflictResp.self, from: data)
        switch fetchError.key {
        case "email":
            return .emailAlreadyInUse
        case "username":
            return .usernameAlreadyInUse
        default:
            return .unknown()
        }
    }
}

