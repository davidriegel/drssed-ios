//
//  Tags.swift
//  Drssed
//
//  Created by David Riegel on 15.08.25.
//

public enum Tags: String, Sendable {
    case CASUAL
    case FORMAL
    case VINTAGE
    case SPORTS
    
    var localizedName: String {
        let key = String.LocalizationValue("common.tag." + self.rawValue.lowercased())
        return String(localized: key)
    }
}
