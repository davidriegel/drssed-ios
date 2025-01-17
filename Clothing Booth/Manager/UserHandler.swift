//
//  UserHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 17.01.25.
//

import Foundation
import UIKit

class UserHandler {
    
    // MARK: GET MY PROFILE
    
    func getMyUserProfile() async throws -> privateUser {
        let request = try await APIHandler.shared.createRequest(endpoint: "/users/me", method: .GET)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        
        return try JSONDecoder().decode(privateUser.self, from: data)
    }
    
    // MARK: -- PUT MY USERNAME
    
    func setUsername(username: String) async throws {
        let uploadData = try! JSONEncoder().encode(["username": username])
        let request = try await APIHandler.shared.createRequest(endpoint: "/users/me/username", method: .PUT, body: uploadData)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: nil)
    }
    
    // MARK: -- PUT MY PROFILEPICTURE
    
    func setProfilePicture(with image: UIImage, _ fileExtension: String) async throws -> privateUser {
        let request = try await APIHandler.shared.createRequest(withImage: image, fileName: "profilePicture.\(fileExtension)", endpoint: "/users/me/profilepicture", method: .PUT)
        let (data, response) = try await URLSession.shared.data(for: request)
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        
        let fetchedData = try JSONDecoder().decode(privateUser.self, from: data)
        return fetchedData
    }
    
    // MARK: -- GET MY PROFILE PICTURE
    
    func getMyProfilePicture() async throws -> URL {
        let request = try await APIHandler.shared.createRequest(endpoint: "/users/me/profilepicture", method: .GET)
        let (data, response) = try await URLSession.shared.data(for: request)
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        
        let fetchedData = try JSONDecoder().decode(imageResponse.self, from: data)
        guard let url = URL(string: fetchedData.path, relativeTo: APIHandler.baseURL) else { throw URLError(.badURL) }
        return url
    }
}
