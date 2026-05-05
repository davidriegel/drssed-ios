//
//  GenerateOutfitsResponse.swift
//  Drssed
//
//  Created by David Riegel on 05.05.26.
//


struct GenerateOutfitsResponse: Codable {
    let outfits: [OutfitAPI]
    let count: Int
}
