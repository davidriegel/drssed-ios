//
//  SimpleOutfit.swift
//  Wearhouse
//
//  Created by David Riegel on 09.03.26.
//

import Foundation

public struct SimpleOutfit: Identifiable, Hashable, Sendable {
    public let id: String
    let createdAt: Date
    let imageID: String
    let isFavorite: Bool
    let isPublic: Bool
    let name: String
    let seasons: [Seasons]
    let tags: [Tags]
    let userID: String
    let clothingIDs: [String]
    
    init(from api: SimpleOutfitAPI) {
        self.id = api.outfit_id
        self.name = api.name
        self.imageID = api.image_id
        self.isFavorite = api.is_favorite
        self.tags = api.tags.compactMap { Tags(rawValue: $0.uppercased()) }
        self.seasons = api.seasons.compactMap { Seasons(rawValue: $0.uppercased()) }
        self.createdAt = api.created_at
        self.isPublic = api.is_public
        self.userID = api.user_id
        self.clothingIDs = api.clothing_ids
    }
}
