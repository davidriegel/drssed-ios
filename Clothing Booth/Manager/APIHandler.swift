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
    
    func _createGETRequest(to endpoint: String, authentication auth: Bool = true) -> URLRequest {
        let endpointURL = URL(string: "http://192.168.2.201:5000/api\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        request.setValue(UserDefaults.standard.string(forKey: "authToken"), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        return request
    }
    
    func _createPOSTRequest(to endpoint: String, with data: Data, authentication auth: Bool = true) -> URLRequest {
        let endpointURL = URL(string: "http://192.168.2.201:5000/api\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = data
        
        if auth {
            request.setValue(UserDefaults.standard.string(forKey: "authToken"), forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func _createPUTRequest(to endpoint: String, with data: Data) -> URLRequest {
        let endpointURL = URL(string: "http://192.168.2.201:5000/api\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        request.setValue(UserDefaults.standard.string(forKey: "authToken"), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = data
        
        return request
    }
    
    func _createPUTRequest(to endpoint: String, withImage image: UIImage, andFileName fileName: String) -> URLRequest? {
        let endpointURL = URL(string: "http://192.168.2.201:5000/api\(endpoint)")!
        var request = URLRequest(url: endpointURL)
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(UserDefaults.standard.string(forKey: "authToken"), forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        
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
    
    func signUpWith(email: String, andPassword: String) async throws -> String {
        let uploadData = try! JSONEncoder().encode(["email": email, "password": andPassword])
        let request = _createPOSTRequest(to: "/signUp", with: uploadData, authentication: false)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 409 else {
            throw signUpError.emailAlreadyInUse
        }
        
        guard statusCode != 429 else {
            throw NetworkingError.rateLimiting
        }
        
        let fetchedData = try JSONDecoder().decode(tokenResponse.self, from: data)
        return fetchedData.token
    }
    
    func signInWith(signInName: String, andPassword: String) async throws -> String {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: signInName)
        
        let signInUse = validEmail ? "email" : "username"
        let uploadData = try! JSONEncoder().encode([signInUse: signInName, "password": andPassword])
        let request = _createPOSTRequest(to: "/signIn", with: uploadData, authentication: false)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 401 else {
            throw NetworkingError.unauthorized
        }
        
        let fetchedData = try JSONDecoder().decode(tokenResponse.self, from: data)
        return fetchedData.token
    }
    
    func setProfilePicture(with image: UIImage, _ fileExtension: String) async throws {
        let request = _createPUTRequest(to: "/users/me/setProfilePicture", withImage: image, andFileName: "profilePicture.png")
        let (_, response) = try await URLSession.shared.data(for: request!)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 400 else { throw NetworkingError.badRequest }
    }
    
    func setUsername(username: String) async throws {
        let uploadData = try! JSONEncoder().encode(["username": username])
        let request = _createPUTRequest(to: "/users/me/setUsername", with: uploadData)
        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = _getStatusCode(response)
        
        guard statusCode != 409 else { throw NetworkingError.conflict }
        guard statusCode != 400 else { throw NetworkingError.badRequest }
    }
    
    func getMyUserProfile() async throws -> User {
        let request = _createGETRequest(to: "/users/me")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func getMyProfilePicture() async throws -> URL {
        let request = _createGETRequest(to: "/users/me/profilePicture")
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = _getStatusCode(response)
        guard statusCode != 404 else { throw NetworkingError.notFound }
        
        let fetchedData = try JSONDecoder().decode(ProfilePicture.self, from: data)
        return URL(string: "http://192.168.2.201:5000" + fetchedData.url)!
    }
}
