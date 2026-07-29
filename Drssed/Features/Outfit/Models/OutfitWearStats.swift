//
//  OutfitWearStats.swift
//  Drssed
//
//  Created by David Riegel on 28.07.26.
//

import Foundation

/// What the wear log says about a single outfit, condensed for its details sheet.
struct OutfitWearStats: Equatable {
    let count: Int
    let lastWorn: OutfitWear?
    /// Only set once at least one entry carries a rating.
    let averageRating: Double?
    /// The occasion the outfit was logged for most often, if any entry names one.
    let favoriteOccasion: WearOccasion?

    static let none = OutfitWearStats(count: 0, lastWorn: nil, averageRating: nil, favoriteOccasion: nil)

    var isEmpty: Bool {
        return count == 0
    }

    init(count: Int, lastWorn: OutfitWear?, averageRating: Double?, favoriteOccasion: WearOccasion?) {
        self.count = count
        self.lastWorn = lastWorn
        self.averageRating = averageRating
        self.favoriteOccasion = favoriteOccasion
    }

    /// Builds the summary from the entries of one outfit, in any order.
    init(wears: [OutfitWear]) {
        guard !wears.isEmpty else {
            self = .none
            return
        }

        let ratings = wears.compactMap(\.rating)

        var occasionCounts: [WearOccasion: Int] = [:]
        for occasion in wears.compactMap(\.occasion) {
            occasionCounts[occasion, default: 0] += 1
        }

        self.count = wears.count
        self.lastWorn = wears.max { $0.wornOn < $1.wornOn }
        self.averageRating = ratings.isEmpty
            ? nil
            : Double(ratings.reduce(0, +)) / Double(ratings.count)
        self.favoriteOccasion = occasionCounts.max { $0.value < $1.value }?.key
    }
}
