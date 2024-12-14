//
//  ConflictResp.swift
//  Clothing Booth
//
//  Created by David Riegel on 11.11.24.
//

import Foundation

// MARK: -- API RESPONSES --

struct error: Codable {
    let error: String
}

struct ConflictResp: Codable {
    let error: String
    let key: String
}

// MARK: -- ERROR MODELS --

enum AuthenticationError: Error {
    case emailAlreadyInUse
    case usernameAlreadyInUse
    case wrongSignInCredentials
}

enum ImageError: Error {
    case imageForegroundUnclear
    case imageTooLarge
}
