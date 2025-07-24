//
//  APIError.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

import UIKit

public enum APIError: Error, Equatable {
    case internalServerError // 500+
    case tooManyRequests // 429
    case unprocessableContent // 422
    case unprocessableContentWithMessage(String, suggestion: String?)
    case payloadTooLarge // 413
    case payloadTooLargeWithMessage(String, suggestion: String?)
    case conflict // 409
    case methodNotAllowed // 405
    case notFound // 404
    case forbidden // 403
    case unauthorized // 401
    case badRequest // 400
    case offline // No internet connection
    case custom(String) // Custom error message
    case unknown // Unexpected error
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.custom, .custom): return false
        case let (a, b): return String(describing: a) == String(describing: b)
        }
    }
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .internalServerError:
            return "A 'internal server error' error has occurred."
        case .tooManyRequests:
            return "A 'too many requests' error has occurred."
        case .unprocessableContent:
            return "A 'unprocessable content' error has occurred."
        case .unprocessableContentWithMessage(let msg, _):
            return msg
        case .payloadTooLarge:
            return "A 'payload too large' error has occurred."
        case .payloadTooLargeWithMessage(let msg, _):
            return msg
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
        case .offline:
            return "A 'offline, no internet connection' error has occurred."
        case .custom(let message):
            return message
        case .unknown:
            return "An unknown error in the code occurred."
        }
    }
}
