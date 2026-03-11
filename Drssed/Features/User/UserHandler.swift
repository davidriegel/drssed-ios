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
    
    // MARK: -- GET MY PROFILE
    
    func getMyUserProfile() async throws -> PrivateUser {
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me", method: .GET)
        let (data, _) = try await APIClient.shared.executeRequest(request: request)
        
        return try JSONDecoder().decode(PrivateUser.self, from: data)
    }
    
    // MARK: -- PUT MY USERNAME
    
    func setUsername(username: String) async throws {
        let uploadData = try! JSONEncoder().encode(["username": username])
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/username", method: .PUT, body: uploadData)
        _ = try await APIClient.shared.executeRequest(request: request)
    }
    
    // MARK: -- PUT MY PROFILEPICTURE
    
    func setProfilePicture(with image: UIImage, _ fileExtension: String) async throws -> PrivateUser {
        let request = try await APIClient.shared.createRequest(withImage: image, endpoint: "/users/me/profilepicture", method: .PUT)
        let (data, _) = try await APIClient.shared.executeRequest(request: request)
        
        let privateUser = try JSONDecoder().decode(PrivateUser.self, from: data)
        return privateUser
    }
    
    // MARK: -- GET MY PROFILE PICTURE
    
    func getMyProfilePicture() async throws -> URL {
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/profilepicture", method: .GET)
        let (data, _) = try await APIClient.shared.executeRequest(request: request)
        
        let imageResponse = try JSONDecoder().decode(ImagePreview.self, from: data)
        guard let url = URL(string: imageResponse.image_url, relativeTo: APIClient.baseURL) else { throw URLError(.badURL) }
        return url
    }
}
