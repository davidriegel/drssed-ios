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

    public func updateOutfit(
        _ domainModel: Outfit,
        previewImageData: Data? = nil,
        previewFilename: String = "preview.jpg",
        previewMimeType: String = "image/jpeg"
    ) async throws -> OutfitAPI {
        var seasonsStrings: [String] = []
        for season in domainModel.seasons {
            seasonsStrings.append(season.rawValue)
        }

        var tagsStrings: [String] = []
        for tag in domainModel.tags {
            tagsStrings.append(tag.rawValue)
        }

        let sceneJSONData = try JSONEncoder().encode(domainModel.scene)
        guard let sceneJSONString = String(data: sceneJSONData, encoding: .utf8) else {
            throw NSError(domain: "OutfitHandler", code: 11, userInfo: [NSLocalizedDescriptionKey: "Failed to encode scene to UTF-8 string"])
        }

        let seasonsJSONData = try JSONEncoder().encode(seasonsStrings)
        guard let seasonsJSONString = String(data: seasonsJSONData, encoding: .utf8) else {
            throw NSError(domain: "OutfitHandler", code: 12, userInfo: [NSLocalizedDescriptionKey: "Failed to encode seasons to UTF-8 string"])
        }

        let tagsJSONData = try JSONEncoder().encode(tagsStrings)
        guard let tagsJSONString = String(data: tagsJSONData, encoding: .utf8) else {
            throw NSError(domain: "OutfitHandler", code: 13, userInfo: [NSLocalizedDescriptionKey: "Failed to encode tags to UTF-8 string"])
        }

        let fields: [String: String] = [
            "name": domainModel.name,
            "seasons": seasonsJSONString,
            "tags": tagsJSONString,
            "scene": sceneJSONString,
            "description": domainModel.description,
            "is_public": domainModel.isPublic ? "true" : "false",
            "is_favorite": domainModel.isFavorite ? "true" : "false"
        ]

        var files: [APIClient.MultipartFile] = []
        if let previewImageData {
            files = [
                .init(
                    fieldName: "preview_image",
                    filename: previewFilename,
                    mimeType: previewMimeType,
                    data: previewImageData
                )
            ]
        }

        let request = try await APIClient.shared.createMultipartRequest(
            endpoint: "/users/me/outfits/\(domainModel.id)",
            method: .PATCH,
            fields: fields,
            files: files
        )

        let outfitWrapper: OutfitWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)
        return outfitWrapper.outfit
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
}

