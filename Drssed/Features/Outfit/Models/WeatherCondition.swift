//
//  WeatherCondition.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

public enum WeatherCondition: String, Sendable, CaseIterable {
    case CLEAR
    case CLOUDY
    case RAIN
    case SNOW
    case WIND
    case FOG
    case STORM

    var localizedName: String {
        let key = String.LocalizationValue("wear.weather." + self.rawValue.lowercased())
        return String(localized: key)
    }

    var symbolName: String {
        switch self {
        case .CLEAR: return "sun.max"
        case .CLOUDY: return "cloud"
        case .RAIN: return "cloud.rain"
        case .SNOW: return "cloud.snow"
        case .WIND: return "wind"
        case .FOG: return "cloud.fog"
        case .STORM: return "cloud.bolt"
        }
    }
}
