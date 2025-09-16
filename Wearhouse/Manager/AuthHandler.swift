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
        let request = try await APIHandler.shared.createRequest(endpoint: "/auth/guest", method: .POST, authentication: false)
        
        do {
            let (data, _) = try await APIHandler.shared.executeRequest(request: request, ignoreError: [])
            
            let tokenResponse = try JSONDecoder().decode(TokenModel.self, from: data)
            
            let jwt = try decode(jwt: tokenResponse.access_token)
            UserDefaults.standard.set(jwt.subject, forKey: "user_id")
            UserDefaults.standard.set(tokenResponse.access_token, forKey: "access_token")
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in)), forKey: "expires_at")
            UserDefaults.standard.set(tokenResponse.refresh_token, forKey: "refresh_token")
            
            return tokenResponse
        }
    }
    
    // MARK: -- GET ACCESS TOKEN
    
    public func getAndRenewAccessToken() async throws -> String {
        guard var accessToken = UserDefaults.standard.string(forKey: "access_token") else { throw AuthenticationError.userNotSignedIn }
        guard let expiresAt = UserDefaults.standard.object(forKey: "expires_at") as? Date else { UserDefaults.standard.removeObject(forKey: "access_token"); throw AuthenticationError.userNotSignedIn }
        
        if Date().addingTimeInterval(TimeInterval(60 * 10)) >= expiresAt {
            guard var refreshToken = UserDefaults.standard.string(forKey: "refresh_token") else { throw AuthenticationError.userNotSignedIn }
            let uploadData = try JSONEncoder().encode(["refresh_token": refreshToken, "access_token": accessToken])
            let request = try await APIHandler.shared.createRequest(endpoint: "/auth/refresh", method: .POST, body: uploadData, authentication: false)
            
            do {
                let tokenModel: TokenModel = try await APIHandler.shared.executeRequestAndDecode(request: request)
                
                accessToken = tokenModel.access_token
                refreshToken = tokenModel.refresh_token
                UserDefaults.standard.set(accessToken, forKey: "access_token")
                UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
                UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(tokenModel.expires_in)), forKey: "expires_at")
            } catch let e {
                // TODO: return to sign up page
                //UserDefaults.standard.removeObject(forKey: "access_token")
                print(e)
                ErrorHandler.handle(e)
                preconditionFailure()
            }
        }
        
        return accessToken
    }
    
    // MARK: -- SIGN UP
    
    public func signUpWith(email: String, username: String, password: String, andProfilePicture profilepicture: String) async throws -> TokenModel {
        guard let uploadData = try? JSONEncoder().encode(["email": email, "username": username, "password": password, "profile_picture": profilepicture]) else {
            fatalError("JSONEncoder failed for known-safe dictionary encoding.")
        }
        
        let request = try await APIHandler.shared.createRequest(endpoint: "/auth/register", method: .POST, body: uploadData, authentication: false)
        
        do {
            let (data, response) = try await APIHandler.shared.executeRequest(request: request, ignoreError: [.conflict])
            
            do {
                try APIHandler.shared.handleHTTPResponse(response, data: data)
            } catch APIError.conflict {
                throw try mapConflictsError(data: data)
            }
            
            let fetchedData = try JSONDecoder().decode(TokenModel.self, from: data)
            
            return fetchedData
        }
    }
    
    // MARK: -- SIGN IN
    
    public func signInWith(signInName: String, andPassword: String) async throws -> TokenModel {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: signInName)
        
        let signInUse = validEmail ? "email" : "username"
        let uploadData = try! JSONEncoder().encode([signInUse: signInName, "password": andPassword])
        let request = try await APIHandler.shared.createRequest(endpoint: "/auth/login", method: .POST, body: uploadData, authentication: false)
        let (data, _) = try await APIHandler.shared.executeRequest(request: request)
        
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
            return .unknown
        }
    }
}
