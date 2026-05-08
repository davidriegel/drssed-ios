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
        
        do {
            _ = try await APIClient.shared.authHandler.getAndRenewAccessToken()
            let state = await getUserType()
            authState = state
        } catch let error as APIError where error.isNetworkRelated() || error.isServerRelated() {
            // TODO: Implement offline mode, proceed with cached state, only viewing mode.
            let state = await getUserType()
            authState = state
            return authState
        } catch {
            ErrorHandler.handleSilently(error)
            authState = .unauthenticated
            return authState
        }
        
        return authState
    }
    
    private func getUserType() async -> AuthState {
        guard let tokens = await TokenManager.shared.currentTokens() else { return .unauthenticated }
        
        do {
            let jwt = try decode(jwt: tokens.accessToken)
            
            if let isGuest = jwt.claim(name: "is_guest").boolean, isGuest {
                return .guest
            }
        } catch {
            return .unauthenticated
        }
        
        return .authenticated
    }
    
    func registerAsGuest() async throws {
        do {
            let tokenResponse = try await APIClient.shared.authHandler.registerAsGuest()
            
            let keychainModel = try TokenKeychainModel(from: tokenResponse)
            await TokenManager.shared.setTokens(keychainModel)
            
            authState = .guest
        } catch {
            authState = .unauthenticated
            throw error
        }
    }
    
    func signInWith(username: String? = nil, email: String? = nil, password: String) async throws {
        do {
            let tokenResponse = try await APIClient.shared.authHandler.signInWith(username: username, email: email, password: password)
            
            let keychainModel = try TokenKeychainModel(from: tokenResponse)
            await TokenManager.shared.setTokens(keychainModel)
            
            SyncCursors.resetAll()
            await SyncManager.shared.syncWithServer(forceFull: true)
            
            authState = .authenticated
        } catch {
            authState = .unauthenticated
            throw error
        }
    }
    
    func upgradeAccount(username: String? = nil, email: String? = nil, password: String, profilePicture: String) async throws -> User {
        do {
            let upgradeAccountResponse = try await APIClient.shared.authHandler.upgradeAccount(username: username, email: email, password: password, profilePicture: profilePicture)
        
            if email != nil {
                try await sendVerificationEmail()
            }
            
            let keychainModel = try TokenKeychainModel(from: upgradeAccountResponse.token)
            await TokenManager.shared.setTokens(keychainModel)
            
            authState = .authenticated
            return upgradeAccountResponse.user
        } catch {
            authState = .unauthenticated
            throw error
        }
    }
    
    func sendVerificationEmail() async throws {
        try await APIClient.shared.authHandler.sendVerificationEmail()
    }
    
    func signOut() async {
        await TokenManager.shared.clearTokens()
        authState = .unauthenticated
    }
}
