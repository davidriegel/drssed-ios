//
//  ClothingCategories.swift
//  Drssed
//
//  Created by David Riegel on 15.08.25.
//

public enum ClothingCategories: String, Codable, CaseIterable, Hashable, Sendable {
    case JACKET
    case TOP
    case BOTTOM
    case FOOTWEAR
    
    var localizedName: String {
        let key = String.LocalizationValue("category_" + self.rawValue.lowercased())
        return String(localized: key)
    }
    
    static func fromLocalized(_ localized: String) -> ClothingCategories? {
        return Self.allCases.first { $0.localizedName == localized }
    }
}
