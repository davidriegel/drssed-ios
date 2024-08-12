//
//  User.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.24.
//

import Foundation

struct User: Codable {
    let userid: String
    let username: String
    let email: String?
}

struct ProfilePicture: Codable {
    let url: String
}
