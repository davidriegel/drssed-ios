//
//  OutfitAPI.swift
//  Drssed
//
//  Created by David Riegel on 02.10.25.
//

import Foundation

public struct OutfitAPI: Codable, Hashable {
    let name: String
    let is_public: Bool
    let is_favorite: Bool
    let created_at: Date
    let updated_at: Date
    let scene: [CanvasPlacement]
    let description: String
    let tags: [String]
    let seasons: [String]
    let user_id: String
    let outfit_id: String
    let image_id: String
    
    func toDomain() -> Outfit {
        return Outfit.init(from: self)
    }
}

public struct OutfitWrapper: Codable {
    let outfit: OutfitAPI
}

struct CanvasPlacement: Codable, Equatable, Hashable {
    let clothing_id: String
    var x: Double
    var y: Double
    var z: Int
    var scale: Double
    var rotation: Double
}
