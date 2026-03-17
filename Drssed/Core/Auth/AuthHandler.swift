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
    
    // MARK: -- GET ACCESS TOKEN
    
    public func getAndRenewAccessToken() async throws -> String {
        guard var tokens = await TokenManager.shared.currentTokens() else { throw AuthenticationError.userNotSignedIn }
        
        if Date().addingTimeInterval(TimeInterval(60 * 10)) >= tokens.expiryDate {
            let uploadData = try JSONEncoder().encode(["refresh_token": tokens.refreshToken, "access_token": tokens.accessToken])
            let request = try await APIClient.shared.createRequest(endpoint: "/auth/refresh", method: .POST, body: uploadData, authentication: false)
            
            let tokenModel: TokenModel = try await APIClient.shared.executeRequestAndDecode(request: request)
            
            let jwt = try decode(jwt: tokenModel.access_token)
            
            guard let is_guest = jwt.claim(name: "is_guest").boolean else {
                throw AuthenticationError.tokenInvalid
            }
                
            let keychainModel = TokenKeychainModel(accessToken: tokenModel.access_token, refreshToken: tokenModel.refresh_token, expiryDate: Date().addingTimeInterval(TimeInterval(tokenModel.expires_in)), isGuest: is_guest)
            await TokenManager.shared.setTokens(keychainModel)
            tokens = keychainModel
        }
        
        return tokens.accessToken
    }
    
    // MARK: -- Upgrade account request logic
    
    // MARK: -- SIGN IN
    
    public func signInWith(signInName: String, andPassword: String) async throws -> TokenModel {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: signInName)
        
        let signInUse = validEmail ? "email" : "username"
        let uploadData = try! JSONEncoder().encode([signInUse: signInName, "password": andPassword])
        let request = try await APIClient.shared.createRequest(endpoint: "/auth/login", method: .POST, body: uploadData, authentication: false)
        let (data, _) = try await APIClient.shared.executeRequest(request: request)
        
        let fetchedData = try JSONDecoder().decode(TokenModel.self, from: data)
        return fetchedData
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

