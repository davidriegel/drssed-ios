//
//  Outfit.swift
//  Wearhouse
//
//  Created by David Riegel on 10.08.25.
//

import Foundation
import UIKit

public struct Outfit: Identifiable, Hashable, Sendable {
    public let id: String
    var updatedAt: Date
    let createdAt: Date
    var imageID: String
    var description: String
    var isPublic: Bool
    var isFavorite: Bool
    var name: String
    var scene: [CanvasPlacement]
    var seasons: [Seasons]
    var tags: [Tags]
    let userID: String
    
    init(name: String, imageID: String, itemDescription: String, isPublic: Bool = true, isFavorite: Bool = false, seasons: [Seasons], tags: [Tags], scene: [CanvasPlacement]) {
        self.id = UUID().uuidString
        self.name = name
        self.imageID = imageID
        self.description = itemDescription
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPublic = isPublic
        self.isFavorite = isFavorite
        self.seasons = seasons
        self.tags = tags
        self.userID = UUID().uuidString
        self.scene = scene
    }
    
    init(from local: OutfitLocal) {
        self.id = local.id
        self.name = local.name
        self.description = local.itemDescription
        self.imageID = local.imageID
        self.isPublic = local.isPublic
        self.tags = local.tags.compactMap { Tags(rawValue: $0) }
        self.seasons = local.seasons.compactMap { Seasons(rawValue: $0) }
        self.createdAt = local.createdAt
        self.updatedAt = local.updatedAt
        self.userID = local.userID
        self.isFavorite = local.isFavorite
        self.scene = local.scene
    }
    
    init(from api: OutfitAPI) {
        self.id = api.outfit_id
        self.name = api.name
        self.description = api.description
        self.imageID = api.image_id
        self.isPublic = api.is_public
        self.isFavorite = api.is_favorite
        self.tags = api.tags.compactMap { Tags(rawValue: $0.uppercased()) }
        self.seasons = api.seasons.compactMap { Seasons(rawValue: $0.uppercased()) }
        self.createdAt = api.created_at
        self.updatedAt = api.updated_at
        self.userID = api.user_id
        self.scene = api.scene
    }
}

extension Outfit {
    func toAPI() -> OutfitAPI {
        return OutfitAPI(
            name: self.name,
            is_public: self.isPublic,
            is_favorite: self.isFavorite,
            created_at: self.createdAt, updated_at: self.updatedAt,
            scene: self.scene,
            description: self.description,
            tags: self.tags.map { $0.rawValue.lowercased() },
            seasons: self.seasons.map { $0.rawValue.lowercased() },
            user_id: self.userID,
            outfit_id: self.id,
            image_id: self.imageID
        )
    }
}
