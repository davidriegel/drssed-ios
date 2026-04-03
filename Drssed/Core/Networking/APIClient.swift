//
//  APIClient.swift
//  Drssed
//
//  Created by David Riegel on 09.05.24.
//

import Foundation
import Network
import UIKit

final public class APIClient {
    public static let shared = APIClient()
    #if DEBUG
    public static let baseURL = URL(string: "http://127.0.0.1:8000") // Debug mode
    #else
    public static let baseURL = URL(string: "https://api.drssed.app") // Production mode
    #endif
    public static let clothingImagesURL = URL(string: "/uploads/clothing_images/", relativeTo: baseURL)
    public static let profileImagesURL = URL(string: "/uploads/profile_pictures/", relativeTo: baseURL)
    public static let outfitImagesURL = URL(string: "/uploads/outfit_images/", relativeTo: baseURL)
    
    public let decoder: JSONDecoder
    private let session: URLSession
    
    let authHandler: AuthHandler = AuthHandler()
    let userHandler: UserHandler = UserHandler()
    let clothingHandler: ClothingHandler = ClothingHandler()
    let outfitHandler: OutfitHandler = OutfitHandler()
    
    public enum requestMethods {
        case GET
        case PUT
        case POST
        case PATCH
        case DELETE
    }
    
    private init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 60
        
        session = URLSession(configuration: config)
    }
    
    // MARK: -- Error Handling
    
    public func handleHTTPResponse(_ response: HTTPURLResponse?, data: Data?) throws {
        guard let statusCode = response?.statusCode else {
            throw APIError.unknown(statusCode: nil)
        }
        
        if (200...299).contains(statusCode) {
            return
        }
        
        var errorMessage: String?
        
        if let data = data, let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            errorMessage = errorResponse.error
        }
        
        // Map status codes to APIError
        switch statusCode {
        case 400:
            throw APIError.badRequest(message: errorMessage)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 405:
            throw APIError.methodNotAllowed
        case 409:
            throw APIError.conflict(message: errorMessage)
        case 413:
            throw APIError.payloadTooLarge(message: errorMessage, suggestion: nil)
        case 422:
            throw APIError.unprocessableContent(message: errorMessage, suggestion: nil)
        case 429:
            throw APIError.tooManyRequests
        case 503:
            throw APIError.serverUnavailable
        case 500...599:
            throw APIError.internalServerError
        default:
            throw APIError.unknown(statusCode: statusCode)
        }
    }
    
    // MARK: -- Create requests
    
    public func createRequest(endpoint: String, method: requestMethods, body: Data? = nil, headers: [String: String]? = nil, authentication: Bool = true, timeoutIntervall: Double? = nil) async throws -> URLRequest {
        guard let url = URL(string: endpoint, relativeTo: APIClient.baseURL) else { throw APIError.badRequest(message: "Invalid endpoint URL") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "\(method)"
        request.httpBody = body
        request.allHTTPHeaderFields = try await prepareHeaders(customHeaders: headers, authentication: authentication)
        
        if let timeoutIntervall = timeoutIntervall {
            request.timeoutInterval = timeoutIntervall
        }
        
        return request
    }
    
    public func createRequest(withImage image: UIImage, endpoint: String, method: requestMethods) async throws -> URLRequest {
        guard let imageData = image.compressedData(maxSizeMB: 4.8) else {
            throw APIError.payloadTooLarge(message: "Image compression failed", suggestion: "Please try a different image")
        }
        
        #if DEBUG
        print("Image size: \(imageData.count / 1024) kbytes")
        #endif
        
        let boundary = UUID().uuidString
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--".data(using: .utf8)!)
        
        return try await createRequest(endpoint: endpoint, method: method, body: data, headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)"], timeoutIntervall: 120)
    }

    private func prepareHeaders(customHeaders: [String: String]? = nil, authentication: Bool = true) async throws -> [String: String] {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if authentication {
            defaultHeaders["Authorization"] = try await self.authHandler.getAndRenewAccessToken()
        }
        
        guard (customHeaders != nil) else {
            return defaultHeaders
        }
        
        // Merge both dictionaries and use customHeader for duplicate key
        return defaultHeaders.merging(customHeaders ?? [:]) { _, custom in custom }
    }
    
    // MARK: -- Execute request
    
    public func executeRequest(request: URLRequest, ignoreError: [APIError] = []) async throws -> (Data, HTTPURLResponse?) {
        guard NetworkManager.shared.isReachable else {
            throw APIError.offline
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            do {
                try handleHTTPResponse(response as? HTTPURLResponse, data: data)
            } catch let error as APIError {
                if !ignoreError.contains(error) {
                    throw error
                }
            }
            
            return (data, response as? HTTPURLResponse)
        } catch let error as URLError {
            throw mapURLError(error)
        }
    }
    
    public func executeRequestAndDecode<T: Decodable>(request: URLRequest, ignoreError: [APIError] = []) async throws -> T {
        let (data, _) = try await executeRequest(request: request, ignoreError: ignoreError)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔴 DECODING ERROR")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("Expected Type: \(T.self)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📄 Response Data:")
            print(String(data: data, encoding: .utf8) ?? "No Data")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("Error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            #endif
            throw error
        }
    }
    
    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .unknown(statusCode: nil)
        }
    }
}
