//
//  AuthenticationError.swift
//  Clothing Booth
//
//  Created by David Riegel on 28.04.25.
//

import Foundation

public enum AuthenticationError: Error {
    // Sign In errors
    case userNotSignedIn
    case invalidCredentials
    
    // Sign Up errors
    case emailAlreadyInUse
    case usernameAlreadyInUse
    case weakPassword
    case invalidEmail
    
    // Token errors
    case tokenExpired
    case tokenInvalid
    case refreshTokenFailed
    
    // General
    case unknown(Error? = nil)
}

extension AuthenticationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        // Sign In errors
        case .userNotSignedIn:
            return String(localized: "error.auth.notSignedIn.description")
        case .invalidCredentials:
            return String(localized: "error.auth.invalidCredentials.description")
            
        // Sign Up errors
        case .emailAlreadyInUse:
            return String(localized: "error.auth.emailInUse.description")
        case .usernameAlreadyInUse:
            return String(localized: "error.auth.usernameInUse.description")
        case .weakPassword:
            return String(localized: "error.auth.weakPassword.description")
        case .invalidEmail:
            return String(localized: "error.auth.invalidEmail.description")
            
        // Token errors
        case .tokenExpired:
            return String(localized: "error.auth.tokenExpired.description")
        case .tokenInvalid:
            return String(localized: "error.auth.tokenInvalid.description")
        case .refreshTokenFailed:
            return String(localized: "error.auth.refreshTokenFailed.description")
            
        // General
        case .unknown(let error):
            if let underlyingError = error {
                return String(format: NSLocalizedString("error.auth.unknownWithDetail.description", comment: ""), underlyingError.localizedDescription)
            }
            
            return String(localized: "error.auth.unknown.description")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .userNotSignedIn:
            return String(localized: "error.auth.notSignedIn.suggestion")
        case .invalidCredentials:
            return String(localized: "error.auth.invalidCredentials.suggestion")
        case .emailAlreadyInUse:
            return String(localized: "error.auth.emailInUse.suggestion")
        case .usernameAlreadyInUse:
            return String(localized: "error.auth.usernameInUse.suggestion")
        case .weakPassword:
            return String(localized: "error.auth.weakPassword.suggestion")
        case .invalidEmail:
            return String(localized: "error.auth.invalidEmail.suggestion")
        case .tokenExpired, .tokenInvalid, .refreshTokenFailed:
            return String(localized: "error.auth.tokenError.suggestion")
        case .unknown:
            return String(localized: "error.auth.unknown.suggestion")
        }
    }
}
