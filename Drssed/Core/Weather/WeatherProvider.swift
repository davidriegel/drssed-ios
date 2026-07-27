//
//  WeatherProvider.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import CoreLocation
import WeatherKit

/// The current conditions, reduced to what a wear can store.
struct WeatherSnapshot: Hashable, Sendable {
    let condition: Drssed.WeatherCondition
    let temperature: Double
    let feelsLike: Double
}

/// Reads the current weather at the user's position from Apple WeatherKit.
///
/// Every failure – no location, no permission, no WeatherKit entitlement – ends up as
/// `nil`: prefilling is a convenience and must never block logging a wear.
actor WeatherProvider {
    static let shared = WeatherProvider()

    private let service = WeatherKit.WeatherService.shared
    private var cached: (snapshot: WeatherSnapshot, at: Date)?

    private static let cacheLifetime: TimeInterval = 10 * 60
    /// Beaufort 6, from where the wind is the thing you actually dress for.
    private static let windyKilometersPerHour: Double = 39

    private init() {}

    func currentWeather() async -> WeatherSnapshot? {
        if let cached, Date().timeIntervalSince(cached.at) < Self.cacheLifetime {
            return cached.snapshot
        }

        guard let location = await LocationProvider.shared.currentLocation() else {
            return nil
        }

        do {
            let current = try await service.weather(for: location, including: .current)

            let snapshot = WeatherSnapshot(
                condition: Self.condition(
                    from: current.condition,
                    windSpeed: current.wind.speed.converted(to: .kilometersPerHour).value
                ),
                temperature: Self.celsius(current.temperature),
                feelsLike: Self.celsius(current.apparentTemperature)
            )

            cached = (snapshot, Date())

            return snapshot
        } catch {
            ErrorHandler.handleSilently(error)
            return nil
        }
    }

    private static func celsius(_ measurement: Measurement<UnitTemperature>) -> Double {
        return (measurement.converted(to: .celsius).value * 10).rounded() / 10
    }

    /// Maps the WeatherKit conditions onto the seven conditions a wear can hold.
    private static func condition(
        from condition: WeatherKit.WeatherCondition,
        windSpeed: Double
    ) -> Drssed.WeatherCondition {
        switch condition {
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms,
             .hurricane, .tropicalStorm, .hail:
            return .STORM

        case .drizzle, .rain, .heavyRain, .sunShowers, .freezingRain, .freezingDrizzle:
            return .RAIN

        case .snow, .heavySnow, .blizzard, .blowingSnow, .flurries, .sunFlurries,
             .sleet, .wintryMix:
            return .SNOW

        case .foggy, .haze, .smoky, .blowingDust:
            return .FOG

        case .breezy, .windy:
            return .WIND

        case .clear, .mostlyClear, .hot, .frigid:
            return windSpeed >= windyKilometersPerHour ? .WIND : .CLEAR

        default:
            return windSpeed >= windyKilometersPerHour ? .WIND : .CLOUDY
        }
    }
}
