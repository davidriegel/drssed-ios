//
//  TokenResp.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import Foundation

public struct TokenModel: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String
}

public struct TokenKeychainModel: Codable {
    let accessToken: String
    let refreshToken: String
    let expiryDate: Date
    let isGuest: Bool
}
