//
//  ClothingModel.swift
//  Clothing Booth
//
//  Created by David Riegel on 14.11.24.
//

import Foundation

struct Clothing: Codable {
    let clothing_id: String
    let name: String
    let description: String?
    let category: String
    let tags: [String]
    let seasons: [String]
    let color: String
    let image: String
    let created_at: String
    let user_id: String
}

struct ClothingList: Codable {
    let clothing: [Clothing]
    let limit: Int
    let offset: Int
}
