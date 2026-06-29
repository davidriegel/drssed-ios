//
//  ClothingSubCategories.swift
//  Drssed
//
//  Created by David Riegel on 02.05.26.
//


public enum ClothingSubCategories: String, Codable, CaseIterable, Hashable, Sendable {
    case T_SHIRT = "T-SHIRT"
    case SHIRT
    case POLO_SHIRT
    case SWEATER
    case HOODIE

    case JEANS
    case TROUSERS
    case SHORTS
    case SKIRT

    case JACKET
    case DENIM_JACKET
    case SPORTS_JACKET
    case COAT
    case BLAZER

    case DRESS

    var localizedName: String {
        let normalized = self.rawValue.lowercased().replacingOccurrences(of: "-", with: "_")
        let key = String.LocalizationValue("subcategory_" + normalized)
        return String(localized: key)
    }

    var category: ClothingCategories {
        switch self {
        case .T_SHIRT, .SHIRT, .POLO_SHIRT, .SWEATER, .HOODIE:
            return .TOP
        case .JEANS, .TROUSERS, .SHORTS, .SKIRT:
            return .BOTTOM
        case .JACKET, .DENIM_JACKET, .SPORTS_JACKET, .COAT, .BLAZER:
            return .JACKET
        case .DRESS:
            return .ONE_PIECE
        }
    }
}

extension ClothingCategories {
    var subCategories: [ClothingSubCategories] {
        ClothingSubCategories.allCases.filter { $0.category == self }
    }
}
