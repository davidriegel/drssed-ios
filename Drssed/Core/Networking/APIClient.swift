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
    public static let baseURL = URL(string: "https://api.drssed.app") // Debug mode
    #else
    public static let baseURL = URL(string: "https://api.drssed.app") // Production mode
    #endif
    public static let clothingImagesURL = URL(string: "/static/clothing_images/", relativeTo: baseURL)
    public static let profileImagesURL = URL(string: "/static/profile_pictures/", relativeTo: baseURL)
    public static let outfitImagesURL = URL(string: "/static/outfit_images/", relativeTo: baseURL)
    
    static let maxAutomaticRetryDelay: TimeInterval = 5

    /// The ceiling the session puts on any single request. The image upload used to
    /// ask for more than this, which the session silently ignored.
    static let resourceTimeout: TimeInterval = 60

    /// The server rejects anything above this outright, so compressing any further
    /// than it is pointless and stopping any sooner would upload a doomed request.
    static let maxImageUploadMB: Double = 4

    public let decoder: JSONDecoder
    private let session: URLSession
    
    let authHandler: AuthHandler = AuthHandler()
    let userHandler: UserHandler = UserHandler()
    let clothingHandler: ClothingHandler = ClothingHandler()
    let outfitHandler: OutfitHandler = OutfitHandler()
    let wearHandler: WearHandler = WearHandler()
    
    public enum requestMethods {
        case GET
        case PUT
        case POST
        case PATCH
        case DELETE
    }
    
    private init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .drssedISO8601
        self.decoder = decoder
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = APIClient.resourceTimeout
        
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
            let conflictKey = data.flatMap { try? JSONDecoder().decode(ConflictResp.self, from: $0) }?.field
            throw APIError.conflict(message: errorMessage, key: conflictKey)
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
        guard let imageData = image.compressedData(maxSizeMB: APIClient.maxImageUploadMB) else {
            throw APIError.payloadTooLarge(message: "Image compression failed", suggestion: "Please try a different image")
        }
        
        let boundary = UUID().uuidString
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--".data(using: .utf8)!)
        
        return try await createRequest(endpoint: endpoint, method: method, body: data, headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)"], timeoutIntervall: APIClient.resourceTimeout)
    }

    private func prepareHeaders(customHeaders: [String: String]? = nil, authentication: Bool = true) async throws -> [String: String] {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if authentication {
            let accessToken = try await self.authHandler.getAndRenewAccessToken()
            
            defaultHeaders["Authorization"] = "Bearer " + accessToken
        }
        
        guard (customHeaders != nil) else {
            return defaultHeaders
        }
        
        // Merge both dictionaries and use customHeader for duplicate key
        return defaultHeaders.merging(customHeaders ?? [:]) { _, custom in custom }
    }
    
    // MARK: -- Execute request
    
    public func executeRequest(request: URLRequest, ignoreError: [APIError] = []) async throws -> (Data, HTTPURLResponse?) {
        try await executeRequest(request: request, ignoreError: ignoreError, isRetry: false, didWaitOutRateLimit: false, didRetryLostConnection: false)
    }

    private func executeRequest(request: URLRequest, ignoreError: [APIError], isRetry: Bool, didWaitOutRateLimit: Bool, didRetryLostConnection: Bool) async throws -> (Data, HTTPURLResponse?) {
        guard NetworkManager.shared.isReachable else {
            throw APIError.offline
        }

        do {
            let (data, response) = try await session.data(for: request)

            do {
                try handleHTTPResponse(response as? HTTPURLResponse, data: data)
            } catch let error as APIError {
                if error == .unauthorized, !isRetry, !ignoreError.contains(error),
                   let retried = await renewedRequest(from: request) {
                    return try await executeRequest(request: retried, ignoreError: ignoreError, isRetry: true, didWaitOutRateLimit: didWaitOutRateLimit, didRetryLostConnection: didRetryLostConnection)
                }

                if error == .tooManyRequests, !didWaitOutRateLimit, !ignoreError.contains(error),
                   let delay = Self.retryDelay(from: response as? HTTPURLResponse) {
                    try await Task.sleep(for: .seconds(delay))
                    return try await executeRequest(request: request, ignoreError: ignoreError, isRetry: isRetry, didWaitOutRateLimit: true, didRetryLostConnection: didRetryLostConnection)
                }

                if !ignoreError.contains(error) {
                    throw error
                }
            }

            return (data, response as? HTTPURLResponse)
        } catch let error as URLError {
            // A pooled connection the server closed in the meantime fails before the
            // request is written, so it never reached anyone and sending it again is
            // safe. Retrying alone is not enough: without dropping the pool first the
            // retry picks the same dead connection and hangs until the resource
            // timeout instead of failing, which is worse than the original error.
            if error.code == .networkConnectionLost, !didRetryLostConnection {
                await session.dropPooledConnections()

                return try await executeRequest(request: request, ignoreError: ignoreError, isRetry: isRetry, didWaitOutRateLimit: didWaitOutRateLimit, didRetryLostConnection: true)
            }

            throw mapURLError(error)
        }
    }

    /// Waits out a rate limit only when the server says it clears within `maxAutomaticRetryDelay`.
    /// Longer limits are surfaced instead, so the user is told rather than left waiting.
    static func retryDelay(from response: HTTPURLResponse?) -> TimeInterval? {
        guard let header = response?.value(forHTTPHeaderField: "Retry-After"),
              let seconds = TimeInterval(header.trimmingCharacters(in: .whitespaces)),
              seconds > 0, seconds <= maxAutomaticRetryDelay else {
            return nil
        }

        return seconds
    }
    
    private func renewedRequest(from request: URLRequest) async -> URLRequest? {
        guard request.value(forHTTPHeaderField: "Authorization") != nil else { return nil }

        let accessToken: String

        do {
            accessToken = try await TokenManager.shared.validAccessToken(forceRefresh: true)
        } catch let error as APIError where error.isNetworkRelated() || error.isServerRelated() {
            ErrorHandler.handleSilently(error)
            return nil
        } catch {
            ErrorHandler.handleSilently(error)
            await AuthenticationManager.shared.signOut()
            return nil
        }

        var renewed = request
        renewed.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")

        return renewed
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

private extension URLSession {
    /// Drops the kept-alive connections, so the next request opens a new one.
    func dropPooledConnections() async {
        await withCheckedContinuation { continuation in
            flush { continuation.resume() }
        }
    }
}
