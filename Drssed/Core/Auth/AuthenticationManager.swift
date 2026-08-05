//
//  AuthenticationManager.swift
//  Drssed
//
//  Created by David Riegel on 17.03.26.
//

import Foundation
import JWTDecode
import Combine

public enum AuthState {
    case unknown
    case guest
    case authenticated
    case unauthenticated
}

@MainActor
class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    private let authStateSubject = CurrentValueSubject<AuthState, Never>(.unknown)
    
    var authState: AuthState { authStateSubject.value }
    
    var authStatePublisher: AnyPublisher<AuthState, Never> { authStateSubject.eraseToAnyPublisher() }
    
    private func setAuthState(_ newState: AuthState) {
        authStateSubject.send(newState)
    }
    
    func determineCurrentAuthState() async -> AuthState {
        guard await TokenManager.shared.currentTokens() != nil else { setAuthState(.unauthenticated); return .unauthenticated }
        
        do {
            _ = try await APIClient.shared.authHandler.getAndRenewAccessToken()
            let state = await getUserType()
            setAuthState(state)
        } catch let error as APIError where error.isNetworkRelated() || error.isServerRelated() {
            // TODO: Implement offline mode, proceed with cached state, only viewing mode.
            let state = await getUserType()
            setAuthState(state)
            return authState
        } catch {
            ErrorHandler.handleSilently(error)
            setAuthState(.unauthenticated)
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
        let tokenResponse = try await APIClient.shared.authHandler.registerAsGuest()
        
        let keychainModel = try TokenKeychainModel(from: tokenResponse)
        try await TokenManager.shared.setTokens(keychainModel)
        
        setAuthState(.guest)
        await AppRepository.shared.userRepository.refreshCurrentUser()
    }
    
    func signInWith(username: String? = nil, email: String? = nil, password: String) async throws {
        let tokenResponse = try await APIClient.shared.authHandler.signInWith(username: username, email: email, password: password)
        
        let keychainModel = try TokenKeychainModel(from: tokenResponse)
        try await TokenManager.shared.setTokens(keychainModel)
        
        await SyncManager.shared.clearSyncState()
        await SyncManager.shared.syncWithServer(forceFull: true)
        
        setAuthState(.authenticated)
        await AppRepository.shared.userRepository.refreshCurrentUser()
    }
    
    func upgradeAccount(username: String? = nil, email: String? = nil, password: String, profilePicture: String) async throws -> User {
        let upgradeAccountResponse = try await APIClient.shared.authHandler.upgradeAccount(username: username, email: email, password: password, profilePicture: profilePicture)
        let keychainModel = try TokenKeychainModel(from: upgradeAccountResponse.token)
        try await TokenManager.shared.setTokens(keychainModel)
        
        try AppRepository.shared.userRepository.setCurrentUser(upgradeAccountResponse.user.toDomain())
        setAuthState(.authenticated)
        return upgradeAccountResponse.user.toDomain()
    }
    
    func registerAccount(username: String? = nil, email: String? = nil, password: String, profilePicture: String) async throws {
        let tokenResponse = try await APIClient.shared.authHandler.registerAccount(username: username, email: email, password: password, profilePicture: profilePicture)
        
        let keychainModel = try TokenKeychainModel(from: tokenResponse)
        try await TokenManager.shared.setTokens(keychainModel)
        
        await SyncManager.shared.clearSyncState()
        await SyncManager.shared.syncWithServer(forceFull: true)
        
        setAuthState(.authenticated)
        await AppRepository.shared.userRepository.refreshCurrentUser()
    }
    
    func sendVerificationEmail() async throws {
        try await APIClient.shared.authHandler.sendVerificationEmail()
    }

    func requestPasswordReset(email: String) async throws {
        try await APIClient.shared.authHandler.requestPasswordReset(email: email)
    }
    
    /// Signing out and deleting leave the app without an account on purpose: minting a
    /// fresh guest right away would bury the choice between registering, signing in and
    /// carrying on as a guest – and would leave an abandoned account behind every time.
    func signOut() async {
        guard let token = await TokenManager.shared.currentTokens() else { return }

        Task.detached {
            try? await APIClient.shared.authHandler.invalidateRefreshToken(refreshToken: token.refreshToken)
        }

        AppRepository.shared.userRepository.clear()

        await SyncManager.shared.clearSyncState()
        await TokenManager.shared.clearTokens()

        setAuthState(.unauthenticated)
    }

    func deleteAccount() async throws {
        try await APIClient.shared.authHandler.deleteAccount()
        await SyncManager.shared.clearSyncState()
        await TokenManager.shared.clearTokens()
        AppRepository.shared.userRepository.clear()

        setAuthState(.unauthenticated)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        do {
            try await APIClient.shared.userHandler.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        } catch APIError.unauthorized {
            throw AuthenticationError.invalidCredentials
        }
    }

    func changeEmail(currentPassword: String, newEmail: String) async throws {
        do {
            try await APIClient.shared.userHandler.changeEmail(currentPassword: currentPassword, newEmail: newEmail)
            await AppRepository.shared.userRepository.refreshCurrentUser()
        } catch APIError.unauthorized {
            throw AuthenticationError.invalidCredentials
        }
    }
}
