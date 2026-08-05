//
//  ClothingModel.swift
//  Clothing Booth
//
//  Created by David Riegel on 14.11.24.
//

import Foundation

public struct ClothingAPI: Codable, Hashable {
    let category: ClothingCategories
    let sub_category: ClothingSubCategories
    let clothing_id, color: String
    let created_at: Date
    let updated_at: Date
    let image_id: String
    let is_public: Bool
    let name: String
    let seasons, tags: [String]
    let warmth_level: Int?
    let user_id: String

    func toDomain() -> Clothing {
        return Clothing.init(from: self)
    }
}

public struct ClothingWrapper: Decodable {
    let clothing: ClothingAPI
}
