//
//  WearHandler.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import Foundation

final class WearHandler {

    init() {}

    private let dateFormatter: ISO8601DateFormatter = ISO8601DateFormatter()

    // MARK: -- Sync wears with server

    func syncWears(updatedSince: Date?) async throws -> SyncronizationResponse<OutfitWearAPI> {
        var endpoint = "/users/me/outfit-wears/sync"

        if let updatedSince {
            let iso = dateFormatter.string(from: updatedSince)
            endpoint += "?updated_since=\(iso)"
        }

        let request = try await APIClient.shared.createRequest(endpoint: endpoint, method: .GET)
        let response: SyncronizationResponse<OutfitWearAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)

        return response
    }

    // MARK: -- POST LOG A WEAR

    public func logWear(
        outfitID: String,
        wornOn: Date? = nil,
        feelsLike: Double? = nil,
        temperature: Double? = nil,
        weather: WeatherCondition? = nil,
        occasion: WearOccasion? = nil,
        rating: Int? = nil,
        note: String? = nil
    ) async throws -> OutfitWearAPI {
        var requestBody: [String: Any] = [:]

        if let wornOn { requestBody["worn_on"] = dateFormatter.string(from: wornOn) }
        if let feelsLike { requestBody["feels_like"] = feelsLike }
        if let temperature { requestBody["temperature"] = temperature }
        if let weather { requestBody["weather"] = weather.rawValue }
        if let occasion { requestBody["occasion"] = occasion.rawValue }
        if let rating { requestBody["rating"] = rating }
        if let note, !note.isEmpty { requestBody["note"] = note }

        let uploadData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = try await APIClient.shared.createRequest(endpoint: "/outfits/\(outfitID)/wears", method: .POST, body: uploadData)
        let wearWrapper: OutfitWearWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)

        return wearWrapper.wear
    }

    // MARK: -- PATCH UPDATE A WEAR

    /// Sends only the fields that actually changed. Cleared fields are sent as `null`
    /// so the server resets them.
    public func patchWear(_ oldDomainModel: OutfitWear, _ newDomainModel: OutfitWear) async throws -> OutfitWearAPI {
        var requestBody: [String: Any] = [:]

        if oldDomainModel.wornOn != newDomainModel.wornOn {
            requestBody["worn_on"] = dateFormatter.string(from: newDomainModel.wornOn)
        }

        if oldDomainModel.feelsLike != newDomainModel.feelsLike {
            requestBody["feels_like"] = newDomainModel.feelsLike ?? NSNull()
        }

        if oldDomainModel.temperature != newDomainModel.temperature {
            requestBody["temperature"] = newDomainModel.temperature ?? NSNull()
        }

        if oldDomainModel.weather != newDomainModel.weather {
            requestBody["weather"] = newDomainModel.weather?.rawValue ?? NSNull()
        }

        if oldDomainModel.occasion != newDomainModel.occasion {
            requestBody["occasion"] = newDomainModel.occasion?.rawValue ?? NSNull()
        }

        if oldDomainModel.rating != newDomainModel.rating {
            requestBody["rating"] = newDomainModel.rating ?? NSNull()
        }

        if oldDomainModel.note != newDomainModel.note {
            requestBody["note"] = newDomainModel.note ?? NSNull()
        }

        guard !requestBody.isEmpty else {
            return newDomainModel.toAPI()
        }

        let uploadData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = try await APIClient.shared.createRequest(endpoint: "/outfits/wears/\(newDomainModel.id)", method: .PATCH, body: uploadData)
        let wearWrapper: OutfitWearWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)

        return wearWrapper.wear
    }

    // MARK: -- GET WEARS OF AN OUTFIT

    func getWears(outfitID: String, limit: Int = 50, offset: Int = 0) async throws -> PaginatedResponse<OutfitWearAPI> {
        let request = try await APIClient.shared.createRequest(endpoint: "/outfits/\(outfitID)/wears?limit=\(limit)&offset=\(offset)", method: .GET)
        let wearsWrapper: PaginatedResponse<OutfitWearAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)

        return wearsWrapper
    }

    // MARK: -- DELETE WEAR BY ID

    func deleteWearByID(wearID: String) async throws -> Void {
        let request = try await APIClient.shared.createRequest(endpoint: "/outfits/wears/\(wearID)", method: .DELETE)
        _ = try await APIClient.shared.executeRequest(request: request)
    }
}
