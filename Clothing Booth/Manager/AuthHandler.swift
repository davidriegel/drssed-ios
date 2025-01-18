//
//  AuthHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 16.01.25.
//

import Foundation
import UIKit

enum AuthenticationError: Error {
    case emailAlreadyInUse
    case usernameAlreadyInUse
    case unknown
}

class AuthHandler {
    
    // MARK: -- GET ACCESS TOKEN
    
    func getAccessToken() async -> String {
        let expiresAt = UserDefaults.standard.object(forKey: "expires_at") as! Date
        var accesToken = UserDefaults.standard.string(forKey: "access_token")!
        if Date().addingTimeInterval(TimeInterval(60 * 10)) >= expiresAt {
            let refreshToken = UserDefaults.standard.string(forKey: "refresh_token")!
            let uploadData = try! JSONEncoder().encode(["refresh_token": refreshToken])
            let request = try! await APIHandler.shared.createRequest(endpoint: "/auth/refresh", method: .POST, body: uploadData, authentication: false)
            
            let (data, response) = try! await URLSession.shared.data(for: request)
            
            do {
                try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
            } catch _ {
                // TODO: return to sign up page
                UserDefaults.standard.removeObject(forKey: "access_token")
                preconditionFailure()
            }
            
            let fetchedData = try! JSONDecoder().decode(tokenModel.self, from: data)
            
            accesToken = fetchedData.access_token
            UserDefaults.standard.set(accesToken, forKey: "access_token")
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(fetchedData.expires_in)), forKey: "expires_at")
        }
        
        return accesToken
    }
    
    // MARK: -- SIGN UP
    
    func signUpWith(email: String, username: String, password: String, andProfilePicture profilepicture: String) async throws -> tokenModel {
        guard let uploadData = try? JSONEncoder().encode(["email": email, "username": username, "password": password, "profile_picture": profilepicture]) else {
            fatalError("JSONEncoder failed for known-safe dictionary encoding.")
        }
        
        let request = try await APIHandler.shared.createRequest(endpoint: "/auth/register", method: .POST, body: uploadData, authentication: false)
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        do {
            try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        } catch APIError.conflict {
            throw try mapConflictsError(data: data)
        }
        
        let fetchedData = try JSONDecoder().decode(tokenModel.self, from: data)
        return fetchedData
    }
    
    // MARK: -- SIGN IN
    
    func signInWith(signInName: String, andPassword: String) async throws -> tokenModel {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: signInName)
        
        let signInUse = validEmail ? "email" : "username"
        let uploadData = try! JSONEncoder().encode([signInUse: signInName, "password": andPassword])
        let request = try await APIHandler.shared.createRequest(endpoint: "/auth/login", method: .POST, body: uploadData, authentication: false)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        
        let fetchedData = try JSONDecoder().decode(tokenModel.self, from: data)
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
