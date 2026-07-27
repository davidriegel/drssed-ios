//
//  WearOccasion.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

public enum WearOccasion: String, Sendable, CaseIterable {
    case EVERYDAY
    case WORK
    case SCHOOL
    case SPORTS
    case PARTY
    case DATE
    case FORMAL
    case TRAVEL
    case HOME

    var localizedName: String {
        let key = String.LocalizationValue("wear.occasion." + self.rawValue.lowercased())
        return String(localized: key)
    }

    var symbolName: String {
        switch self {
        case .EVERYDAY: return "figure.walk"
        case .WORK: return "briefcase"
        case .SCHOOL: return "book"
        case .SPORTS: return "figure.run"
        case .PARTY: return "party.popper"
        case .DATE: return "heart"
        case .FORMAL: return "theatermasks"
        case .TRAVEL: return "airplane"
        case .HOME: return "house"
        }
    }
}
