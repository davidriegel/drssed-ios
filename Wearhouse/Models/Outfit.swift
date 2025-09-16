//
//  Outfit.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.25.
//

import Foundation

public struct OutfitWrapper: Codable {
    let outfit: Outfit
}

public struct OutfitsWrapper: Codable {
    let limit: Int
    let offset: Int
    let outfits: [Outfit]
}

public struct Outfit: Codable, Hashable {
    let name: String
    let is_public: Bool
    let is_favorite: Bool
    let created_at: Date
    let clothing_ids: [String]
    let description: String
    let tags: [String]
    let seasons: [String]
    let user_id: String
    let outfit_id: String
    let image_id: String
}
