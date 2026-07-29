//
//  RecommendOutfitsResponse.swift
//  Drssed
//
//  Created by David Riegel on 28.07.26.
//

import Foundation

/// A recommended outfit as the server sends it.
///
/// The recommendation endpoint answers with summaries only: they carry no scene, which is why
/// a recommendation is resolved against the local store before it reaches the UI.
public struct OutfitSummaryAPI: Codable, Hashable {
    let outfit_id: String
    let is_public: Bool
    let is_favorite: Bool
    let name: String
    let created_at: Date
    let updated_at: Date
    let user_id: String
    let seasons: [String]
    let tags: [String]
}

struct RecommendOutfitsResponse: Codable {
    let outfits: [OutfitSummaryAPI]
    let count: Int
}
