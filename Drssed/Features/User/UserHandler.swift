//
//  UserHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 17.01.25.
//

import Foundation
import UIKit

class UserHandler {
    
    init() {}
    
    func fetchCurrentUser() async throws -> UserAPI {
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me", method: .GET)
        let user: UserAPIWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)

        return user.user
    }

    /// Answers with the renewed token pair: changing the password revokes every
    /// refresh token the account had, so the reply is the only way to stay signed in.
    func changePassword(currentPassword: String, newPassword: String) async throws -> TokenAPIResponse {
        let payload = ["current_password": currentPassword, "new_password": newPassword]
        let body = try JSONEncoder().encode(payload)
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/password", method: .PATCH, body: body)

        let wrapper: TokenWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)

        return wrapper.token
    }

    func changeEmail(currentPassword: String, newEmail: String) async throws {
        let payload = ["current_password": currentPassword, "new_email": newEmail]
        let body = try JSONEncoder().encode(payload)
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/email", method: .PATCH, body: body)

        do {
            _ = try await APIClient.shared.executeRequest(request: request)
        } catch APIError.conflict(_, let key) {
            throw AuthenticationError.forConflict(key: key)
        }
    }
}
