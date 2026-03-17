//
//  AuthenticationManager.swift
//  Drssed
//
//  Created by David Riegel on 17.03.26.
//
/*
import Foundation
import JWTDecode

actor AuthenticationManager {
    static let shared = AuthenticationManager()
    
    enum AuthState {
        case unknown
        case guest
        case authenticated
        case unauthenticated
    }
    
    private(set) var authState: AuthState = .unknown
    
    func determineCurrentAuthState() async -> AuthState {
        guard let tokens = await TokenManager.shared.currentTokens() else { return .unauthenticated }
        
        if Date().addingTimeInterval(TimeInterval(60 * 5)) >= tokens.expiryDate {
            do {
                _ = try await APIClient.shared.authHandler.getAndRenewAccessToken()
                let state = await getUserType()
                authState = state
                
                return state
            } catch let error as APIError {
                return 
                await TokenManager.shared.clearTokens()
                authState = .unauthenticated
                return .unauthenticated
            }
        }
        
        let state = await getUserType()
        authState = state
        
        return state
    }
    
    private func getUserType() async -> AuthState {
        guard let tokens = await TokenManager.shared.currentTokens() else { return .unauthenticated }
        
        let jwt = try decode(jwt: tokens.accessToken)
        
        if let userType = jwt.claim(name: "is_guest").boolean, userType == true {
            return .guest
        }
        
        return .authenticated
    }
}
*/
