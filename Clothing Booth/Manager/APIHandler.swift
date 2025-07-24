//
//  APIHandler.swift
//  Outfitter
//
//  Created by David Riegel on 09.05.24.
//

import Foundation
import Network
import UIKit

final public class APIHandler {
    public static let shared = APIHandler()
    public static let baseURL = URL(string: "https://api.clothing-booth.com")
    
    let authHandler: AuthHandler = AuthHandler()
    let userHandler: UserHandler = UserHandler()
    let clothingHandler: ClothingHandler = ClothingHandler()
    
    public enum requestMethods {
        case GET
        case PUT
        case POST
        case DELETE
    }
    
    private init() {}
    
    // MARK: -- Error Handling
    
    public func handleHTTPResponse(_ response: HTTPURLResponse?, data: Data?) throws {
        guard let statusCode = response?.statusCode else { throw APIError.unknown }
        
        switch statusCode {
        case 200...299:
            return
        case 400:
            throw APIError.badRequest
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 405:
            throw APIError.methodNotAllowed
        case 409:
            throw APIError.conflict
        case 413:
            throw APIError.payloadTooLarge
        case 422:
            throw APIError.unprocessableContent
        case 429:
            throw APIError.tooManyRequests
        case 500...599:
            throw APIError.internalServerError
        default:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
            throw APIError.custom(message + " Status code: [\(statusCode)]")
        }
    }
    
    // MARK: -- Create requests
    
    public func createRequest(endpoint: String, method: requestMethods, body: Data? = nil, headers: [String: String]? = nil, authentication: Bool = true) async throws -> URLRequest {
        guard NetworkManager.shared.isConnected else { throw APIError.offline }
        
        guard let url = URL(string: endpoint, relativeTo: APIHandler.baseURL) else { throw APIError.badRequest }
        
        var request = URLRequest(url: url)
        request.httpMethod = "\(method)"
        request.httpBody = body
        request.allHTTPHeaderFields = try await prepareHeaders(customHeaders: headers, authentication: authentication)
        
        return request
    }
    
    public func createRequest(withImage image: UIImage, fileName: String, endpoint: String, method: requestMethods) async throws -> URLRequest {
        guard let imageData = fileName.hasSuffix("png") ? image.pngData() : image.jpegData(compressionQuality: 1) else {
            fatalError("couldn't compress image")
        }
        
        let boundary = UUID().uuidString
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(fileName.hasSuffix("png") ? "image/png" : "image/jpeg")\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--".data(using: .utf8)!)
        
        return try await createRequest(endpoint: endpoint, method: method, body: data, headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)"])
    }
    
    private func prepareHeaders(customHeaders: [String: String]? = nil, authentication: Bool = true) async throws -> [String: String] {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if authentication {
            defaultHeaders["Authorization"] = try await self.authHandler.getAccessToken()
        }
        
        guard (customHeaders != nil) else {
            return defaultHeaders
        }
        
        // Merge both dictionaries and use customHeader for duplicate key
        return defaultHeaders.merging(customHeaders ?? [:]) { _, custom in custom }
    }
    
    // MARK: -- Execute request
    
    public func executeRequest(request: URLRequest, ignoreError: [APIError]? = nil) async throws -> (Data, HTTPURLResponse?) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            do {
                try handleHTTPResponse(response as? HTTPURLResponse, data: data)
            } catch let error as APIError {
                guard let ignoredErrorList = ignoreError else { throw error }
                
                if !ignoredErrorList.contains(error) {
                    throw error
                }
            }
            
            return (data, response as? HTTPURLResponse)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                throw APIError.offline
            default:
                throw APIError.custom(error.localizedDescription)
            }
        }
    }
}
