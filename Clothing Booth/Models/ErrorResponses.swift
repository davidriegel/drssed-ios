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
