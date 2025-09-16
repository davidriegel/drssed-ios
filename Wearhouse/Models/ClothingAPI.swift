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
    
    public func update(name: String? = nil, description: String? = nil, category: ClothingCategories? = nil, tags: [String]? = nil, seasons: [String]? = nil, color: String? = nil, image: String? = nil, is_public: Bool? = nil) -> ClothingAPI {
        return ClothingAPI(category: category ?? self.category, clothing_id: self.clothing_id, color: color ?? self.color, created_at: self.created_at, description: description ?? self.description, image_id: image ?? self.image_id, is_public: is_public ?? self.is_public, name: name ?? self.name, seasons: seasons ?? self.seasons, tags: tags ?? self.tags, user_id: self.user_id)
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
