//
//  ConflictResp.swift
//  Clothing Booth
//
//  Created by David Riegel on 11.11.24.
//

import Foundation

public struct ConflictResp: Codable {
    let error: String
    /// Names the input that clashed. Absent when the conflict is not about one
    /// particular input, so the whole body still decodes.
    let field: String?
}
