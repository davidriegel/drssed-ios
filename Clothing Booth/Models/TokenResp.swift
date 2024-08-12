//
//  TokenResp.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import Foundation

struct tokenResponse: Codable {
    let token: String
}

enum signUpError: Error {
    case emailAlreadyInUse
}

enum signInError: Error {
    case wrongCredentials
}

struct error: Codable {
    let error: String
}
