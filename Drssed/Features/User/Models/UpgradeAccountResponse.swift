//
//  UpgradeAccountResponse.swift
//  Drssed
//
//  Created by David Riegel on 08.05.26.
//

struct UpgradeAccountResponse: Codable {
    let user: User
    let token: TokenAPIResponse
}
