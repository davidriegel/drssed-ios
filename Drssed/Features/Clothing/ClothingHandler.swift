//
//  ClothingHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 17.01.25.
//

import Foundation
import UIKit

final class ClothingHandler {
    
    init() {}
    
    // MARK: -- Sync clothes with server
    func syncClothes(updatedSince: Date?) async throws -> SyncronizationResponse<ClothingAPI> {
        var endpoint = "/users/me/clothing/sync"
            
        if let updatedSince {
            let iso = ISO8601DateFormatter().string(from: updatedSince)
            endpoint += "?updated_since=\(iso)"
        }
            
        let request = try await APIClient.shared.createRequest(endpoint: endpoint, method: .GET)
        let response: SyncronizationResponse<ClothingAPI> = try await APIClient.shared.executeRequestAndDecode(request: request)
            
        return response
    }
    
    // MARK: -- POST REMOVE CLOTHING BACKGROUND
    
    public func removeClothingBackground(from image: UIImage) async throws -> (String, URL, UIColor, ClothingCategories, ClothingSubCategories) {
        let uploadRequest = try await APIClient.shared.createRequest(withImage: image, endpoint: "/images/preview", method: .POST)
        let job: ImagePreviewJob = try await APIClient.shared.executeRequestAndDecode(request: uploadRequest)

        let maxAttempts = 60
        let pollInterval: UInt64 = 1_000_000_000

        for _ in 0..<maxAttempts {
            let statusRequest = try await APIClient.shared.createRequest(endpoint: "/images/preview/\(job.job_id)", method: .GET)
            let status: ImagePreviewStatus = try await APIClient.shared.executeRequestAndDecode(request: statusRequest)

            switch status.status {
            case "ready":
                guard let urlString = status.image_url, let imageID = status.image_id, let colorHex = status.image_color, let category = status.image_category, let subCategory = status.image_sub_category, let url = URL(string: urlString, relativeTo: APIClient.baseURL) else {
                    throw URLError(.badServerResponse)
                }
                
                return (imageID, url, UIColor(hex: colorHex) ?? .white, category, subCategory)
            case "failed":
                throw APIError.unprocessableContent(
                    message: String(localized: "imagepicker.backgroundRemoval.error"),
                    suggestion: String(localized: "imagepicker.uploadimage.hint")
                )

            default:  // "processing"
                try await Task.sleep(nanoseconds: pollInterval)
            }
        }

        throw URLError(.timedOut)
    }
    
    // MARK: -- POST UPLOAD CLOATHING
    
    public func uploadClothing(_ domainModel: Clothing) async throws -> ClothingAPI {
        var seasonsStrings: [String] = []
        for season in domainModel.seasons {
            seasonsStrings.append(season.rawValue)
        }
        
        var tagsStrings: [String] = []
        for tag in domainModel.tags {
            tagsStrings.append(tag.rawValue)
        }
        
        let uploadDict = ["name": domainModel.name, "category": domainModel.category.rawValue, "sub_category": domainModel.subCategory.rawValue, "seasons": seasonsStrings, "tags": tagsStrings, "image_id": domainModel.imageID, "color": domainModel.color.hexString, "warmth_level": domainModel.warmth.rawValue] as [String : Any]
        
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIClient.shared.createRequest(endpoint: "/users/me/clothing", method: .POST, body: uploadData)
        let clothingWrapper: ClothingWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return clothingWrapper.clothing
    }
    
    // MARK: -- GET MY CLOTHING
    
    public func getMyClothing(limit: Int = 20, offset: Int = 0, category: ClothingCategories? = nil) async throws -> ClothingsWrapper {
        guard let userID = UserDefaults.standard.string(forKey: "user_id") else { throw AuthenticationError.userNotSignedIn }
        
        return try await getClothingList(userID: userID, limit: limit, offset: offset, category: category)
    }
    
    // MARK: -- GET CLOTHING BY USER ID
    
    public func getClothingList(userID: String, limit: Int = 20, offset: Int = 0, category: ClothingCategories? = nil) async throws -> ClothingsWrapper {
        var endpoint = "/users/\(userID)/clothing?limit=\(limit)&offset=\(offset)"
        
        if let category = category {
            endpoint += "&category=\(category)"
        }
        
        let request = try await APIClient.shared.createRequest(endpoint: endpoint, method: .GET, authentication: true)
        let clothingList: ClothingsWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)
    
        return clothingList
    }
    
    // MARK: -- PATCH EDIT CLOTHING
    
    public func patchEditClothing(oldClothing: ClothingAPI, name: String?, description: String?, category: String?, tags: [String]?, seasons: [String]?, color: UIColor?, image_id: String?) async throws -> ClothingAPI {
        var uploadDict: [String:Any] = [:]
        
        if let name = name {
            uploadDict["name"] = name
        }
        
        if let description = description {
            uploadDict["description"] = description
        }
        
        if let category = category {
            uploadDict["category"] = category
        }
        
        if let tags = tags {
            uploadDict["tags"] = tags
        }
        
        if let seasons = seasons {
            uploadDict["seasons"] = seasons
        }
        
        if let color = color {
            uploadDict["color"] = color.hexString
        }
        
        if let image_id = image_id {
            uploadDict["image_id"] = image_id
        }
        
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIClient.shared.createRequest(endpoint: "/clothing/\(oldClothing.clothing_id)", method: .PATCH, body: uploadData)
        let clothingWrapper: ClothingWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return clothingWrapper.clothing
    }
    
    public func patchEditClothing(oldClothing: Clothing, newClothing: Clothing) async throws -> ClothingAPI {
        var uploadDict: [String:Any] = [:]
        
        if oldClothing.name != newClothing.name {
            uploadDict["name"] = newClothing.name
        }
        
        if oldClothing.category != newClothing.category {
            uploadDict["category"] = newClothing.category.rawValue
        }
        
        if oldClothing.subCategory != newClothing.subCategory {
            uploadDict["sub_category"] = newClothing.subCategory.rawValue
        }
        
        if oldClothing.tags != newClothing.tags {
            uploadDict["tags"] = newClothing.tags.map(\.rawValue)
        }
        
        if oldClothing.seasons != newClothing.seasons {
            uploadDict["seasons"] = newClothing.seasons.map(\.rawValue)
        }
        
        if oldClothing.color != newClothing.color {
            uploadDict["color"] = newClothing.color.hexString
        }
        
        if oldClothing.imageID != newClothing.imageID {
            uploadDict["image_id"] = newClothing.imageID
        }

        if oldClothing.warmth != newClothing.warmth {
            uploadDict["warmth_level"] = newClothing.warmth.rawValue
        }

        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIClient.shared.createRequest(endpoint: "/clothing/\(oldClothing.id)", method: .PATCH, body: uploadData)
        let clothingWrapper: ClothingWrapper = try await APIClient.shared.executeRequestAndDecode(request: request)
        
        return clothingWrapper.clothing
    }
    
    // MARK: -- DELETE CLOTHING
    
    public func deleteClothingByID(clothingID: String) async throws {
        let request = try await APIClient.shared.createRequest(endpoint: "/clothing/\(clothingID)", method: .DELETE)
        _ = try await APIClient.shared.executeRequest(request: request)
    }
}
