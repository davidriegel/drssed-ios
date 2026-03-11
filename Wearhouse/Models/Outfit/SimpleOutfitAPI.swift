//
//  SimpleOutfitAPI.swift
//  Wearhouse
//
//  Created by David Riegel on 09.03.26.
//

import Foundation

public struct SimpleOutfitAPI: Codable, Hashable {
    let outfit_id: String
    let image_id: String
    let is_public: Bool
    let is_favorite: Bool
    let created_at: Date
    let name: String
    let tags: [String]
    let seasons: [String]
    let user_id: String
    let clothing_ids: [String]
    
    func toDomain() -> SimpleOutfit {
        return SimpleOutfit.init(from: self)
    }
}
