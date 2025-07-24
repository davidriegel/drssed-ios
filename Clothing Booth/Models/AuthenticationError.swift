//
//  AuthenticationError.swift
//  Clothing Booth
//
//  Created by David Riegel on 28.04.25.
//

public enum AuthenticationError: Error {
    case userNotSignedIn
    case emailAlreadyInUse
    case usernameAlreadyInUse
    case unknown
}
