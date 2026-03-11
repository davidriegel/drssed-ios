//
//  PaginatedResponse.swift
//  Wearhouse
//
//  Created by David Riegel on 09.03.26.
//

import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let limit: Int
    let offset: Int
    let total: Int
}
