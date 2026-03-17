//
//  APIError.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

import UIKit

public struct APIErrorResponse: Codable {
    let error: String
}

public enum APIError: Error {
    // Network-related
    case offline // No internet connection available
    case timeout // Request timeout
    
    // Authentication
    case unauthorized // 401 - Token invalid
    case forbidden // 403 - Not allowed
    
    // Client errors
    case badRequest(message: String? = nil) // 400
    case notFound // 404
    case methodNotAllowed // 405
    case conflict(message: String? = nil) // 409
    case payloadTooLarge(message: String? = nil, suggestion: String?) // 413
    case unprocessableContent(message: String? = nil, suggestion: String?) // 422
    case tooManyRequests // 429
    
    // Server errors
    case internalServerError // 500+
    case serverUnavailable // 503
    
    // Other
    case unknown(statusCode: Int? = nil)
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline),
             (.timeout, .timeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.methodNotAllowed, .methodNotAllowed),
             (.tooManyRequests, .tooManyRequests),
             (.internalServerError, .internalServerError),
             (.serverUnavailable, .serverUnavailable):
            return true
            
        case (.badRequest(let a), .badRequest(let b)):
            return a == b
            
        case (.conflict(let a), .conflict(let b)):
            return a == b
            
        case (.payloadTooLarge(let msgA, let suggA), .payloadTooLarge(let msgB, let suggB)):
            return msgA == msgB && suggA == suggB
            
        case (.unprocessableContent(let msgA, let suggA), .unprocessableContent(let msgB, let suggB)):
            return msgA == msgB && suggA == suggB
            
        case (.unknown(let a), .unknown(let b)):
            return a == b
            
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        // Network Errors
        case .offline:
            return String(localized: "error.api.offline.description")
        case .timeout:
            return String(localized: "error.api.timeout.description")
            
        // Client Errors
        case .badRequest(let message):
            return message ?? String(localized: "error.api.badRequest.description")
        case .unauthorized:
            return String(localized: "error.api.unauthorized.description")
        case .forbidden:
            return String(localized: "error.api.forbidden.description")
        case .notFound:
            return String(localized: "error.api.notFound.description")
        case .methodNotAllowed:
            return String(localized: "error.api.methodNotAllowed.description")
        case .conflict(let message):
            return message ?? String(localized: "error.api.conflict.description")
        case .payloadTooLarge(let message, _):
            return message ?? String(localized: "error.api.payloadTooLarge.description")
        case .unprocessableContent(let message, _):
            return message ?? String(localized: "error.api.unprocessableContent.description")
        case .tooManyRequests:
            return String(localized: "error.api.tooManyRequests.description")
            
        // Server Errors
        case .internalServerError:
            return String(localized: "error.api.internalServerError.description")
        case .serverUnavailable:
            return String(localized: "error.api.serverUnavailable.description")
            
        // Unknown
        case .unknown(let statusCode):
            if let code = statusCode {
                return String(format: NSLocalizedString("error.api.unknown.descriptionWithCode", comment: ""), Int64(code))
            }
            return String(localized: "error.api.unknown.description")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .offline:
            return String(localized: "error.api.offline.suggestion")
        case .timeout:
            return String(localized: "error.api.timeout.suggestion")
        case .unauthorized:
            return String(localized: "error.api.unauthorized.suggestion")
        case .forbidden:
            return String(localized: "error.api.forbidden.suggestion")
        case .notFound:
            return String(localized: "error.api.notFound.suggestion")
        case .conflict:
            return String(localized: "error.api.conflict.suggestion")
        case .payloadTooLarge(_, let suggestion):
            return suggestion ?? String(localized: "error.api.payloadTooLarge.suggestion")
        case .unprocessableContent(_, let suggestion):
            return suggestion ?? String(localized: "error.api.unprocessableContent.suggestion")
        case .tooManyRequests:
            return String(localized: "error.api.tooManyRequests.suggestion")
        case .internalServerError, .serverUnavailable:
            return String(localized: "error.api.serverError.suggestion")
        case .badRequest, .methodNotAllowed, .unknown:
            return String(localized: "error.api.generic.suggestion")
        }
    }
}
