//
//  ClothingAPI 2.swift
//  Wearhouse
//
//  Created by David Riegel on 17.09.25.
//

import Foundation
import UIKit

public struct Clothing: Identifiable, Hashable, Sendable {
    public let id: String
    var category: ClothingCategories
    var updatedAt: Date
    let createdAt: Date
    var imageID: String
    var description: String
    var color: UIColor
    var isPublic: Bool
    var name: String
    var seasons: [Seasons]
    var tags: [Tags]
    let userID: String
    
    init(name: String, imageID: String, category: ClothingCategories, itemDescription: String, color: UIColor, isPublic: Bool = true, seasons: [Seasons], tags: [Tags]) {
        self.id = UUID().uuidString
        self.name = name
        self.imageID = imageID
        self.category = category
        self.description = itemDescription
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPublic = isPublic
        self.seasons = seasons
        self.tags = tags
        self.userID = UUID().uuidString
    }
    
    init(from local: ClothingLocal) {
        self.id = local.id
        self.name = local.name
        self.category = ClothingCategories(rawValue: local.category)!
        self.color = UIColor(hex: local.color) ?? .white
        self.description = local.itemDescription
        self.imageID = local.imageID
        self.isPublic = local.isPublic
        self.tags = local.tags.compactMap { Tags(rawValue: $0) }
        self.seasons = local.seasons.compactMap { Seasons(rawValue: $0) }
        self.createdAt = local.createdAt
        self.updatedAt = local.updatedAt
        self.userID = local.userID
    }
    
    init(from api: ClothingAPI) {
        self.id = api.clothing_id
        self.name = api.name
        self.category = api.category
        self.color = UIColor(hex: api.color) ?? .white
        self.description = api.description
        self.imageID = api.image_id
        self.isPublic = api.is_public
        self.tags = api.tags.compactMap { Tags(rawValue: $0.uppercased()) }
        self.seasons = api.seasons.compactMap { Seasons(rawValue: $0.uppercased()) }
        self.createdAt = api.created_at
        self.updatedAt = Date()
        self.userID = api.user_id
    }
}
