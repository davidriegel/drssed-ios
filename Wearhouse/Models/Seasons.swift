//
//  Seasons.swift
//  Wearhouse
//
//  Created by David Riegel on 15.08.25.
//

public enum Seasons: String, Sendable {
    case SPRING
    case SUMMER
    case AUTUMN
    case WINTER
    
    var localizedName: String {
        let key = String.LocalizationValue("seasons_" + self.rawValue.lowercased())
        return String(localized: key)
    }
}
