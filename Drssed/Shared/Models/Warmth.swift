//
//  Warmth.swift
//  Drssed
//
//  Created by David Riegel on 01.07.26.
//

import Foundation

public enum Warmth: Int, Sendable, CaseIterable {
    case AIRY = 1
    case LIGHT = 2
    case MILD = 3
    case WARM = 4
    case TOASTY = 5

    var localizedName: String {
        switch self {
        case .AIRY:   return String(localized: "common.warmth.airy")
        case .LIGHT:  return String(localized: "common.warmth.light")
        case .MILD:   return String(localized: "common.warmth.mild")
        case .WARM:   return String(localized: "common.warmth.warm")
        case .TOASTY: return String(localized: "common.warmth.toasty")
        }
    }

    var symbolName: String {
        switch self {
        case .AIRY:   return "wind"
        case .LIGHT:  return "cloud.sun"
        case .MILD:   return "sun.max"
        case .WARM:   return "flame"
        case .TOASTY: return "flame.fill"
        }
    }
}
