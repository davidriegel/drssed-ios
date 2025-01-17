//
//  APIHandler.swift
//  Outfitter
//
//  Created by David Riegel on 09.05.24.
//

import Foundation
import UIKit

enum APIError: Error {
    case internalServerError // 500+
    case tooManyRequests // 429
    case unprocessableContent // 422
    case payloadTooLarge // 413
    case conflict // 409
    case methodNotAllowed // 405
    case notFound // 404
    case forbidden // 403
    case unauthorized // 401
    case badRequest // 400
    case custom(String) // Custom error message
    case unknown // Unexpected error
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .internalServerError:
            return "A 'internal server error' error has occurred."
        case .tooManyRequests:
            return "A 'too many requests' error has occurred."
        case .unprocessableContent:
            return "A 'unprocessable content' error has occurred."
        case .payloadTooLarge:
            return "A 'payload too large' error has occurred."
        case .conflict:
            return "A 'conflict' error has occurred."
        case .methodNotAllowed:
            return "A 'method not allowed' error has occurred."
        case .notFound:
            return "A 'not found' error has occurred."
        case .forbidden:
            return "A 'forbidden' error has occurred."
        case .unauthorized:
            return "A 'unauthorized' error has occurred."
        case .badRequest:
            return "A 'bad request' error has occurred."
        case .custom(let message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

class APIHandler {
    static let shared = APIHandler()
    static let baseURL = URL(string: "https://api.clothing-booth.com")
    
    let authHandler: AuthHandler
    let userHandler: UserHandler
    let clothingHandler: ClothingHandler
    
    enum requestMethods {
        case GET
        case PUT
        case POST
    }
    
    // MARK: -- Error Handling
    
    func handleHTTPResponse(_ response: HTTPURLResponse?, data: Data?) throws {
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
    
    func createRequest(endpoint: String, method: requestMethods, body: Data? = nil, headers: [String: String]? = nil, authentication: Bool = true) async throws -> URLRequest {
        guard let url = URL(string: endpoint, relativeTo: APIHandler.baseURL) else { throw APIError.badRequest }
        
        var request = URLRequest(url: url)
        request.httpMethod = "\(method)"
        request.httpBody = body
        request.allHTTPHeaderFields = await prepareHeaders(customHeaders: headers, authentication: authentication)
        
        return request
    }
    
    func createRequest(withImage image: UIImage, fileName: String, endpoint: String, method: requestMethods) async throws -> URLRequest {
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
    
    private func prepareHeaders(customHeaders: [String: String]? = nil, authentication: Bool = true) async -> [String: String] {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if authentication {
            defaultHeaders["Authorization"] = await self.authHandler.getAccessToken()
        }
        
        guard (customHeaders != nil) else {
            return defaultHeaders
        }
        
        // Merge both dictionaries and use customHeader for duplicate key
        return defaultHeaders.merging(customHeaders ?? [:]) { _, custom in custom }
    }
    
    private init() {
        self.authHandler = AuthHandler()
        self.userHandler = UserHandler()
        self.clothingHandler = ClothingHandler()
    }
}
