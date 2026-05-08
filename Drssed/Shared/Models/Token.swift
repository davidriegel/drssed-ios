//
//  TokenResp.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import Foundation
import JWTDecode

public struct TokenAPIResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String
}

public struct TokenKeychainModel: Codable {
    private static let expiryBuffer: TimeInterval = 60 * 5  // 5 minutes
    
    let accessToken: String
    let refreshToken: String
    let expiryDate: Date
    let isGuest: Bool
    let userID: String
    
    var willExpireSoon: Bool {
        expiryDate <= Date().addingTimeInterval(Self.expiryBuffer)
    }
    
    public init(from response: TokenAPIResponse) throws {
        let jwt = try decode(jwt: response.access_token)
        
        guard let userID = jwt.subject else {
            throw AuthenticationError.tokenInvalid
        }
        
        guard let isGuest = jwt.claim(name: "is_guest").boolean else {
            throw AuthenticationError.tokenInvalid
        }
        
        self.accessToken = response.access_token
        self.refreshToken = response.refresh_token
        self.expiryDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
        self.isGuest = isGuest
        self.userID = userID
    }
}
