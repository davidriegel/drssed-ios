//
//  OutfitHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 24.07.25.
//

import Foundation

final class OutfitHandler {
    
    init() {}
    
    // Sync outfits with server
    func syncOutfits(updatedSince: Date?) async throws -> SyncronizationResponse<OutfitAPI> {
        var endpoint = "/users/me/outfits/sync"
            
        if let updatedSince {
            let iso = ISO8601DateFormatter().string(from: updatedSince)
            endpoint += "?updated_since=\(iso)"
        }
            
        let request = try await APIClient.shared.createRequest(endpoint: endpoint, method: .GET)
        let response: SyncronizationResponse<OutfitAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)
            
        return response
    }
    
    // MARK: -- POST CREATE NEW OUTFIT
    
    public func createNewOutfit(
        _ domainModel: Outfit
    ) async throws -> OutfitAPI {
        var seasonsStrings: [String] = []
        for season in domainModel.seasons {
            seasonsStrings.append(season.rawValue)
        }

        var tagsStrings: [String] = []
        for tag in domainModel.tags {
            tagsStrings.append(tag.rawValue)
        }
        
        let apiModel = domainModel.toAPI()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let uploadData = try encoder.encode(apiModel)
        
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/outfits", method: .POST, body: uploadData)

        let outfitWrapper: OutfitWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)
        return outfitWrapper.outfit
    }

    // MARK: -- PATCH UPDATE OUTFIT
    
    public func patchOutfit(_ domainModel: Outfit) async throws -> OutfitAPI {
        let endpoint = "/outfits/\(domainModel.id)"
        
        let requestBody: [String: Any] = [
            "name": domainModel.name,
            "is_favorite": domainModel.isFavorite,
            "is_public": domainModel.isPublic,
            "seasons": domainModel.seasons.map { $0.rawValue.lowercased() },
            "tags": domainModel.tags.map { $0.rawValue.lowercased() }
        ]
        
        let data = try JSONSerialization.data(withJSONObject: requestBody)
        
        let request = try await APIClient.shared.createRequest(endpoint: "/outfits/\(domainModel.id)", method: .PATCH, body: data)
        let outfitAPIWrapper: ItemWrapper<OutfitAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)

        return outfitAPIWrapper.item
    }
    
    // MARK: -- GET MY OUTFITS
    
    func getMyOutfits(limit: Int = 20, offset: Int = 0) async throws -> PaginatedResponse<SimpleOutfitAPI> {
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/outfits?limit=\(limit)&offset=\(offset)", method: .GET)
        let outfitsWrapper: PaginatedResponse<SimpleOutfitAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return outfitsWrapper
    }
    
    // MARK: -- GET OUTFITS BY USER ID
    
    func getOutfitsByUserID(userID: String, limit: Int = 20, offset: Int = 0) async throws -> PaginatedResponse<OutfitAPI> {
        let request = try await APIClient.shared.createRequest(endpoint: "/users/\(userID)/outfits?limit=\(limit)&offset=\(offset)", method: .GET)
        let outfitsWrapper: PaginatedResponse<OutfitAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return outfitsWrapper
    }
    
    // MARK: -- DELETE OUTFIT BY ID
    
    func deleteOutfitByID(outfitID: String) async throws -> Void {
        let request = try await APIClient.shared.createRequest(endpoint: "/outfits/\(outfitID)", method: .DELETE)
        _ = try await APIClient.shared.executeRequest(request: request)
    }
}

