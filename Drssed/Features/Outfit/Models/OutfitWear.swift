//
//  OutfitWear.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import Foundation

/// A single logged wear of an outfit. The server allows one entry per outfit and day.
public struct OutfitWear: Identifiable, Hashable, Sendable {
    public let id: String
    let userID: String
    let outfitID: String
    var wornOn: Date
    let createdAt: Date
    var updatedAt: Date
    var outfitName: String?
    var feelsLike: Double?
    var temperature: Double?
    var weather: WeatherCondition?
    var occasion: WearOccasion?
    var rating: Int?
    var note: String?
    var clothingIDs: [String]

    init(from local: OutfitWearLocal) {
        self.id = local.id
        self.userID = local.userID
        self.outfitID = local.outfitID
        self.wornOn = local.wornOn
        self.createdAt = local.createdAt
        self.updatedAt = local.updatedAt
        self.outfitName = local.outfitName
        self.feelsLike = local.feelsLike?.doubleValue
        self.temperature = local.temperature?.doubleValue
        self.weather = local.weather.flatMap { WeatherCondition(rawValue: $0) }
        self.occasion = local.occasion.flatMap { WearOccasion(rawValue: $0) }
        self.rating = local.rating?.intValue
        self.note = local.note
        self.clothingIDs = local.clothingIDs
    }

    init(from api: OutfitWearAPI) {
        self.id = api.wear_id
        self.userID = api.user_id
        self.outfitID = api.outfit_id
        self.wornOn = api.worn_on
        self.createdAt = api.created_at
        self.updatedAt = api.updated_at
        self.outfitName = api.outfit_name
        self.feelsLike = api.feels_like
        self.temperature = api.temperature
        self.weather = api.weather.flatMap { WeatherCondition(rawValue: $0.uppercased()) }
        self.occasion = api.occasion.flatMap { WearOccasion(rawValue: $0.uppercased()) }
        self.rating = api.rating
        self.note = api.note
        self.clothingIDs = api.clothing_ids
    }
}

extension OutfitWear {
    func toAPI() -> OutfitWearAPI {
        return OutfitWearAPI(
            wear_id: self.id,
            user_id: self.userID,
            outfit_id: self.outfitID,
            worn_on: self.wornOn,
            created_at: self.createdAt,
            updated_at: self.updatedAt,
            outfit_name: self.outfitName,
            feels_like: self.feelsLike,
            temperature: self.temperature,
            weather: self.weather?.rawValue,
            occasion: self.occasion?.rawValue,
            rating: self.rating,
            note: self.note,
            clothing_ids: self.clothingIDs
        )
    }

    /// True when the entry was logged for the same calendar day as `date`.
    func isOnSameDay(as date: Date, calendar: Calendar = .current) -> Bool {
        return calendar.isDate(wornOn, inSameDayAs: date)
    }
}
