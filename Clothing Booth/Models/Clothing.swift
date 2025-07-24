//
//  ClothingModel.swift
//  Clothing Booth
//
//  Created by David Riegel on 14.11.24.
//

import Foundation

public struct Clothing: Codable {
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
    
    public func update(name: String? = nil, description: String? = nil, category: String? = nil, tags: [String]? = nil, seasons: [String]? = nil, color: String? = nil, image: String? = nil) -> Clothing {
        return Clothing(clothing_id: self.clothing_id, name: name ?? self.name, description: description ?? self.description, category: category ?? self.category, tags: tags ?? self.tags, seasons: seasons ?? self.seasons, color: color ?? self.color, image: image ?? self.image, created_at: self.created_at, user_id: self.user_id)
    }
}

public struct ClothingList: Codable {
    let clothing: [Clothing]
    let limit: Int
    let offset: Int
}
