//
//  AuthenticationManager.swift
//  Drssed
//
//  Created by David Riegel on 17.03.26.
//

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
        
        if Date().addingTimeInterval(TimeInterval(60 * 10)) >= tokens.expiryDate {
            do {
                _ = try await APIClient.shared.authHandler.getAndRenewAccessToken()
                let state = await getUserType()
                authState = state
                
                return state
            } catch let error as APIError {
                if error.isNetworkRelated() || error.isServerRelated() {
                    // TODO: Implement offline mode
                    let state = await getUserType()
                    authState = state
                    return authState
                }
                
                await TokenManager.shared.clearTokens()
                authState = .unauthenticated
                return authState
            } catch {
                ErrorHandler.handleSilently(error)
                authState = .unauthenticated
                return authState
            }
        }
        
        let state = await getUserType()
        authState = state
        
        return state
    }
    
    private func getUserType() async -> AuthState {
        guard let tokens = await TokenManager.shared.currentTokens() else { return .unauthenticated }
        
        do {
            let jwt = try decode(jwt: tokens.accessToken)
            
            if let userType = jwt.claim(name: "is_guest").integer, userType != 0 {
                return .guest
            }
        } catch {
            return .unauthenticated
        }
        
        return .authenticated
    }
    
    func registerAsGuest() async throws {
        do {
            let tokenModel = try await APIClient.shared.authHandler.registerAsGuest()
            authState = .guest
        } catch {
            authState = .unauthenticated
            throw error
        }
    }
    
    // TODO: Add upgrade account logic
    
    func signOut() async {
        await TokenManager.shared.clearTokens()
        authState = .unauthenticated
    }
}
