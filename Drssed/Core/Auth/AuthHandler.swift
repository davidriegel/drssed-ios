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
    
    @discardableResult
    public func registerAsGuest() async throws -> TokenModel {
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/guest", method: .POST, authentication: false)
        
        let (data, _) = try await APIClient.shared.executeRequest(request: request, ignoreError: [])
        
        let tokenResponse = try JSONDecoder().decode(TokenModel.self, from: data)
        
        let jwt = try decode(jwt: tokenResponse.access_token)
        
        guard let is_guest = jwt.claim(name: "is_guest").boolean else { throw AuthenticationError.tokenInvalid }
        
        UserDefaults.standard.set(jwt.subject, forKey: "user_id")
        let keychainModel = TokenKeychainModel(accessToken: tokenResponse.access_token, refreshToken: tokenResponse.refresh_token, expiryDate: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in)), isGuest: is_guest)
        await TokenManager.shared.setTokens(keychainModel)
        
        return tokenResponse
    }
    
    // MARK: -- sign into existing account
    
    @discardableResult
    public func signInWith(username: String? = nil, email: String? = nil, password: String) async throws -> TokenModel {
        guard !(username?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) && !(email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else { throw AuthenticationError.missingCredentials }
        
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
        
        let tokenResponse = try JSONDecoder().decode(TokenModel.self, from: data)
        let jwt = try decode(jwt: tokenResponse.access_token)
        
        UserDefaults.standard.set(jwt.subject, forKey: "user_id")
        let keychainModel = TokenKeychainModel(accessToken: tokenResponse.access_token, refreshToken: tokenResponse.refresh_token, expiryDate: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in)), isGuest: false)
        await TokenManager.shared.setTokens(keychainModel)
        
        return tokenResponse
    }
    
    // MARK: -- GET ACCESS TOKEN
    
    public func getAndRenewAccessToken() async throws -> String {
        guard var tokens = await TokenManager.shared.currentTokens() else { throw AuthenticationError.userNotSignedIn }
        
        if Date().addingTimeInterval(TimeInterval(60 * 10)) >= tokens.expiryDate {
            let uploadData = try JSONEncoder().encode(["refresh_token": tokens.refreshToken, "access_token": tokens.accessToken])
            let request = try await APIClient.shared.createRequest(endpoint: "/auth/refresh", method: .POST, body: uploadData, authentication: false)
            
            let tokenModel: TokenModel = try await APIClient.shared.executeRequestAndDecode(request: request)
            
            let jwt = try decode(jwt: tokenModel.access_token)

            guard let is_guest = jwt.claim(name: "is_guest").integer else {
                throw AuthenticationError.tokenInvalid
            }
                
            let keychainModel = TokenKeychainModel(accessToken: tokenModel.access_token, refreshToken: tokenModel.refresh_token, expiryDate: Date().addingTimeInterval(TimeInterval(tokenModel.expires_in)), isGuest: is_guest != 0)
            await TokenManager.shared.setTokens(keychainModel)
            tokens = keychainModel
        }
        
        return tokens.accessToken
    }
    
    // MARK: -- Upgrade account request logic
    
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

