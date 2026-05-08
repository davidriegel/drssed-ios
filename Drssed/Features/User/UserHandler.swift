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
}
