//
//  OutfitWearAPI.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import Foundation

public struct OutfitWearAPI: Codable, Hashable {
    let wear_id: String
    let user_id: String
    let outfit_id: String
    let worn_on: Date
    let created_at: Date
    let updated_at: Date
    let outfit_name: String?
    let feels_like: Double?
    let temperature: Double?
    let weather: String?
    let occasion: String?
    let rating: Int?
    let note: String?
    let clothing_ids: [String]

    func toDomain() -> OutfitWear {
        return OutfitWear.init(from: self)
    }
}

public struct OutfitWearWrapper: Codable {
    let wear: OutfitWearAPI
}
