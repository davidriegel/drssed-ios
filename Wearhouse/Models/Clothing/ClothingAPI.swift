//
//  ClothingModel.swift
//  Clothing Booth
//
//  Created by David Riegel on 14.11.24.
//

import Foundation

public struct ClothingAPI: Codable, Hashable {
    let category: ClothingCategories
    let clothing_id, color: String
    let created_at: Date
    let description, image_id: String
    let is_public: Bool
    let name: String
    let seasons, tags: [String]
    let user_id: String
    
    func toDomain() -> Clothing {
        return Clothing.init(from: self)
    }
}

public struct ClothingsWrapper: Decodable {
    let clothing: [ClothingAPI]
    let limit: Int
    let offset: Int
}

public struct ClothingWrapper: Decodable {
    let clothing: ClothingAPI
}
