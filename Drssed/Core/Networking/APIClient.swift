//
//  APIClient.swift
//  Outfitter
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

    public struct MultipartFile {
        public let fieldName: String
        public let filename: String
        public let mimeType: String
        public let data: Data

        public init(fieldName: String, filename: String, mimeType: String, data: Data) {
            self.fieldName = fieldName
            self.filename = filename
            self.mimeType = mimeType
            self.data = data
        }
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
        guard let statusCode = response?.statusCode else { throw APIError.unknown }
        
        if !((200...299).contains(statusCode)) {
            if let data = data {
                print(try JSONDecoder().decode(APIErrorResponse.self, from: data).error)
            }
        }
                
        
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
        case 502...504:
            throw APIError.offline
        case 500...599:
            throw APIError.internalServerError
        default:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
            throw APIError.custom(message + " Status code: [\(statusCode)]")
        }
    }
    
    // MARK: -- Create requests
    
    public func createRequest(endpoint: String, method: requestMethods, body: Data? = nil, headers: [String: String]? = nil, authentication: Bool = true, timeoutIntervall: Double? = nil) async throws -> URLRequest {
        guard let url = URL(string: endpoint, relativeTo: APIClient.baseURL) else { throw APIError.badRequest }
        
        var request = URLRequest(url: url)
        request.httpMethod = "\(method)"
        request.httpBody = body
        request.allHTTPHeaderFields = try await prepareHeaders(customHeaders: headers, authentication: authentication)
        
        if let timeoutIntervall = timeoutIntervall {
            request.timeoutInterval = timeoutIntervall
        }
        
        return request
    }

    public func createMultipartRequest(
        endpoint: String,
        method: requestMethods,
        fields: [String: String],
        files: [MultipartFile],
        headers: [String: String]? = nil,
        authentication: Bool = true,
        timeoutIntervall: Double? = nil
    ) async throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = makeMultipartBody(fields: fields, files: files, boundary: boundary)

        var mergedHeaders: [String: String] = headers ?? [:]
        mergedHeaders["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        mergedHeaders["Accept"] = "application/json"

        var request = try await createRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: mergedHeaders,
            authentication: authentication,
            timeoutIntervall: timeoutIntervall
        )

        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        return request
    }
    
    public func createRequest(withImage image: UIImage, endpoint: String, method: requestMethods) async throws -> URLRequest {
        guard let imageData = image.compressedData(maxSizeMB: 4.8) else {
            fatalError("couldn't compress image")
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
    
    private func makeMultipartBody(fields: [String: String], files: [MultipartFile], boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"

        // Text fields
        for (key, value) in fields {
            body.append(Data("--\(boundary)\(crlf)".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\(crlf)\(crlf)".utf8))
            body.append(Data("\(value)\(crlf)".utf8))
        }

        // File fields
        for file in files {
            body.append(Data("--\(boundary)\(crlf)".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.filename)\"\(crlf)".utf8))
            body.append(Data("Content-Type: \(file.mimeType)\(crlf)\(crlf)".utf8))
            body.append(file.data)
            body.append(Data(crlf.utf8))
        }

        // Closing boundary
        body.append(Data("--\(boundary)--\(crlf)".utf8))
        return body
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
            print("Server not reachable, skipping request")
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
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost:
                throw APIError.offline
            default:
                throw APIError.custom(error.localizedDescription)
            }
        }
    }
    
    public func executeRequestAndDecode<T: Decodable>(request: URLRequest, ignoreError: [APIError] = []) async throws -> T {
        let (data, _) = try await executeRequest(request: request, ignoreError: ignoreError)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("📄 Response:\n\(String(data: data, encoding: .utf8) ?? "No Data")")
            #endif
            throw error
        }
    }
}
