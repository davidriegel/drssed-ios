//
//  ClothingSubCategories.swift
//  Drssed
//
//  Created by David Riegel on 02.05.26.
//


public enum ClothingSubCategories: String, Codable, CaseIterable, Hashable, Sendable {
    // TOP
    case T_SHIRT
    case LONGSLEEVE
    case TANK_TOP
    case SHIRT
    case POLO_SHIRT
    case SWEATER
    case HOODIE
    case SWEATSHIRT
    case CARDIGAN
    case VEST
    case TURTLENECK

    // BOTTOM
    case JEANS
    case TROUSERS
    case CHINOS
    case CARGO_PANTS
    case SWEATPANTS
    case LEGGINGS
    case SHORTS
    case SKIRT

    // JACKET
    case DENIM_JACKET
    case SPORTS_JACKET
    case LEATHER_JACKET
    case BOMBER_JACKET
    case PUFFER_JACKET
    case WINDBREAKER
    case RAIN_JACKET
    case PARKA
    case COAT
    case TRENCH_COAT
    case BLAZER

    // ONE_PIECE
    case DRESS
    case JUMPSUIT
    case OVERALL
    case SUIT
    
    case UNKNOWN
    
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ClothingSubCategories(rawValue: rawValue.uppercased()) ?? .UNKNOWN
    }

    var localizedName: String {
        let normalized = self.rawValue.lowercased().replacingOccurrences(of: "-", with: "_")
        let key = String.LocalizationValue("subcategory_" + normalized)
        return String(localized: key)
    }

    var category: ClothingCategories {
        switch self {
        case .T_SHIRT, .LONGSLEEVE, .TANK_TOP, .SHIRT, .POLO_SHIRT, .SWEATER, .HOODIE, .SWEATSHIRT, .CARDIGAN, .VEST, .TURTLENECK:
            return .TOP
        case .JEANS, .TROUSERS, .CHINOS, .CARGO_PANTS, .SWEATPANTS, .LEGGINGS, .SHORTS, .SKIRT:
            return .BOTTOM
        case .DENIM_JACKET, .SPORTS_JACKET, .LEATHER_JACKET, .BOMBER_JACKET, .PUFFER_JACKET, .WINDBREAKER, .RAIN_JACKET, .PARKA, .COAT, .TRENCH_COAT, .BLAZER:
            return .JACKET
        case .DRESS, .JUMPSUIT, .OVERALL, .SUIT:
            return .ONE_PIECE
        case .UNKNOWN:
            return .UNKNOWN
        }
    }
}

extension ClothingCategories {
    var subCategories: [ClothingSubCategories] {
        guard self != .UNKNOWN else { return [] }
        
        return ClothingSubCategories.allCases.filter { $0.category == self }
    }
}
