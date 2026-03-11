//
//  SyncronizationResponse.swift
//  Drssed
//
//  Created by David Riegel on 11.03.26.
//

import Foundation

struct SyncronizationResponse<T: Decodable>: Decodable {
    let updated: [T]
    let deleted: [String]
    let serverTime: Date
    
    enum CodingKeys: String, CodingKey {
        case updated
        case deleted
        case serverTime = "server_time"
    }
}
