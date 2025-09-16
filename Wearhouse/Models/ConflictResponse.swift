//
//  ConflictResp.swift
//  Clothing Booth
//
//  Created by David Riegel on 11.11.24.
//

import Foundation

public struct ConflictResp: Codable {
    let error: String
    let key: String
}
