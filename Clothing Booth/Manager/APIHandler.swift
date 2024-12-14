//
//  APIHandler.swift
//  Outfitter
//
//  Created by David Riegel on 09.05.24.
//

import Foundation
import UIKit

class APIHandler {
    static let shared = APIHandler()
    
    func _createGETRequest(to endpoint: String, authentication auth: Bool = true) async -> URLRequest {
        let endpointURL = URL(string: "https://api.clothing-booth.com\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        
        if auth {
            let accessToken = await _getAccessToken()
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
            
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        return request
    }
    
    func _createPOSTRequest(to endpoint: String, with data: Data, authentication auth: Bool = true) async -> URLRequest {
        let endpointURL = URL(string: "https://api.clothing-booth.com\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = data
        
        if auth {
            let accessToken = await _getAccessToken()
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func _createPUTRequest(to endpoint: String, with data: Data) async -> URLRequest {
        let endpointURL = URL(string: "https://api.clothing-booth.com\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        let accessToken = await _getAccessToken()
                                 
        request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = data
        
        return request
    }
    
    func _createImageRequest(_ method: String, to endpoint: String, withImage image: UIImage, andFileName fileName: String) async -> URLRequest? {
        let endpointURL = URL(string: "https://api.clothing-booth.com\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        let boundary = UUID().uuidString
        let accessToken = await _getAccessToken()
        
        request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = method
        
        var data = Data()
        
        guard let imageData = fileName.hasSuffix("png") ? image.pngData() : image.jpegData(compressionQuality: 1) else {
                return nil
        }
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(fileName.hasSuffix("png") ? "image/png" : "image/jpeg")\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--".data(using: .utf8)!)
        request.httpBody = data
        
        return request
    }
    
    func _getStatusCode(_ response: URLResponse) -> Int {
        guard let httpResponse = response as? HTTPURLResponse else {
            return 0
        }
        
        return httpResponse.statusCode
    }
        
    func _getAccessToken() async -> String {
        let expiresAt = UserDefaults.standard.object(forKey: "expires_at") as! Date
        var accesToken = UserDefaults.standard.string(forKey: "access_token")!
        if Date().addingTimeInterval(TimeInterval(60 * 10)) >= expiresAt {
            let refreshToken = UserDefaults.standard.string(forKey: "refresh_token")!
            let uploadData = try! JSONEncoder().encode(["refresh_token": refreshToken])
            let request = await _createPOSTRequest(to: "/auth/refresh", with: uploadData, authentication: false)
            
            let (data, response) = try! await URLSession.shared.data(for: request)
            let statusCode = _getStatusCode(response)
            
            guard statusCode == 200 else {
                
                // return to sign in
                UserDefaults.standard.removeObject(forKey: "access_token")
                preconditionFailure()
            }
            
            print(try! JSONSerialization.jsonObject(with: data))
            let fetchedData = try! JSONDecoder().decode(tokenModel.self, from: data)
            
            accesToken = fetchedData.access_token
            UserDefaults.standard.set(accesToken, forKey: "access_token")
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(fetchedData.expires_in)), forKey: "expires_at")
        }
        
        return accesToken
    }
    
    func signUpWith(email: String, username: String, andPassword password: String) async throws -> tokenModel {
        let uploadData = try! JSONEncoder().encode(["email": email, "username": username, "password": password])
        let request = await _createPOSTRequest(to: "/auth/register", with: uploadData, authentication: false)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 409 else {
            let fetchError = try JSONDecoder().decode(ConflictResp.self, from: data)
            switch fetchError.key {
            case "email":
                throw AuthenticationError.emailAlreadyInUse
            case "username":
                throw AuthenticationError.usernameAlreadyInUse
            default:
                throw NetworkingError.conflict
            }
        }
        
        guard statusCode != 429 else {
            throw NetworkingError.rateLimiting
        }
        
        let fetchedData = try JSONDecoder().decode(tokenModel.self, from: data)
        return fetchedData
    }
    
    func signInWith(signInName: String, andPassword: String) async throws -> tokenModel {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: signInName)
        print(validEmail)
        print(signInName)
        
        let signInUse = validEmail ? "email" : "username"
        print(signInUse)
        let uploadData = try! JSONEncoder().encode([signInUse: signInName, "password": andPassword])
        let request = await _createPOSTRequest(to: "/auth/login", with: uploadData, authentication: false)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 401 else {
            throw NetworkingError.unauthorized
        }
        
        let fetchedData = try JSONDecoder().decode(tokenModel.self, from: data)
        return fetchedData
    }
    
    func setProfilePicture(with image: UIImage, _ fileExtension: String) async throws -> privateUser {
        let request = await _createImageRequest("PUT", to: "/users/me/profilepicture", withImage: image, andFileName: "profilePicture.\(fileExtension)")
        let (data, response) = try await URLSession.shared.data(for: request!)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 400 else { throw NetworkingError.badRequest }
        
        let fetchedData = try JSONDecoder().decode(privateUser.self, from: data)
        return fetchedData
    }
    
    func setUsername(username: String) async throws {
        let uploadData = try! JSONEncoder().encode(["username": username])
        let request = await _createPUTRequest(to: "/users/me/username", with: uploadData)
        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 409 else { throw NetworkingError.conflict }
        guard statusCode != 400 else { throw NetworkingError.badRequest }
    }
    
    func getMyUserProfile() async throws -> privateUser {
        let request = await _createGETRequest(to: "/users/me")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return try JSONDecoder().decode(privateUser.self, from: data)
    }
    
    func getMyProfilePicture() async throws -> URL {
        let request = await _createGETRequest(to: "/users/me/profilepicture")
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = _getStatusCode(response)
        guard statusCode != 404 else { throw NetworkingError.notFound }
        
        let fetchedData = try JSONDecoder().decode(imageResponse.self, from: data)
        return URL(string: "https://api.clothing-booth.com" + fetchedData.path)!
    }
    
    func removeClothingBackground(from image: UIImage, _ fileExtension: String) async throws -> URL {
        let request = await _createImageRequest("POST", to: "/clothing/backgroundremover", withImage: image, andFileName: "clothingPictrue.\(fileExtension)")
        let (data, response) = try await URLSession.shared.data(for: request!)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 422 else { throw ImageError.imageForegroundUnclear }
        guard statusCode != 413 else { throw ImageError.imageTooLarge }
        guard statusCode != 429 else { throw NetworkingError.rateLimiting }
        
        let fetchedData = try JSONDecoder().decode(imageResponse.self, from: data)
        return URL(string: "https://api.clothing-booth.com" + fetchedData.path)!
    }
    
    func uploadClothing(with name: String, description: String, type: String, seasons: [String], tags: [String], imageURL: String, color: UIColor) async throws -> Clothing {
        let uploadDict = ["name": name, "description": description, "category": type.replacingOccurrences(of: "-", with: ""), "seasons": seasons, "tags": tags, "image_url": imageURL, "color": color.hexStringFromColor(color: color)] as [String : Any]
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = await _createPOSTRequest(to: "/clothing/upload", with: uploadData, authentication: true)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 429 else { throw NetworkingError.rateLimiting }
                
        let fetchedData = try JSONDecoder().decode(Clothing.self, from: data)
        return fetchedData
    }
    
    func getClothingList(limit: Int = 20, offset: Int = 0) async throws -> ClothingList {
        let request = await _createGETRequest(to: "/clothing/list?limit=\(limit)&offset=\(offset)", authentication: true)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 429 else { throw NetworkingError.rateLimiting }
        guard statusCode == 200 else { return ClothingList(clothing: [], limit: limit, offset: offset) }
        
        let fetchedData = try JSONDecoder().decode(ClothingList.self, from: data)
        return fetchedData
    }
}
