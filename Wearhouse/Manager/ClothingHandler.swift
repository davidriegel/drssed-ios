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
    
    // MARK: -- POST REMOVE CLOTHING BACKGROUND
    
    public func removeClothingBackground(from image: UIImage, _ fileExtension: String) async throws -> (URL, UIColor, ClothingCategories) {
        let request = try await APIHandler.shared.createRequest(withImage: image, fileName: "clothingPicture.\(fileExtension)", endpoint: "/images/preview", method: .POST)
        
        let imageResponse: ImagePreview = try await APIHandler.shared.executeRequestAndDecode(request: request)
        
        guard let url = URL(string: imageResponse.image_url, relativeTo: APIHandler.baseURL) else { throw URLError(.badURL) }
        
        return (url, UIColor(hex: imageResponse.image_color) ?? UIColor.white, imageResponse.image_category)
    }
    
    // MARK: -- POST UPLOAD CLOATHING
    
    public func uploadClothing(with name: String, description: String, category: ClothingCategories, seasons: [Seasons], tags: [Tags], imageID: String, color: UIColor) async throws -> ClothingAPI {
        var seasonsStrings: [String] = []
        for season in seasons {
            seasonsStrings.append(season.rawValue)
        }
        
        var tagsStrings: [String] = []
        for tag in tags {
            tagsStrings.append(tag.rawValue)
        }
        
        let uploadDict = ["name": name, "description": description, "category": category.rawValue, "seasons": seasonsStrings, "tags": tagsStrings, "image_id": imageID, "color": color.hexStringFromColor(color: color)] as [String : Any]
        
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIHandler.shared.createRequest(endpoint: "/users/me/clothing", method: .POST, body: uploadData)
        let clothingWrapper: ClothingWrapper = try await APIHandler.shared.executeRequestAndDecode(request: request)
        
        //#if DEBUG
        //print("💻 POST /users/me/clothing Response: \(String(data: data, encoding: .utf8) ?? "No Data")")
        //#endif
        
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
        
        let request = try await APIHandler.shared.createRequest(endpoint: endpoint, method: .GET, authentication: true)
        let clothingList: ClothingsWrapper = try await APIHandler.shared.executeRequestAndDecode(request: request)
    
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
            uploadDict["color"] = color.hexStringFromColor(color: color)
        }
        
        if let image_id = image_id {
            uploadDict["image_id"] = image_id
        }
        
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/\(oldClothing.clothing_id)", method: .PATCH, body: uploadData)
        let clothingWrapper: ClothingWrapper = try await APIHandler.shared.executeRequestAndDecode(request: request)
        
        return clothingWrapper.clothing
    }
    
    // MARK: -- DELETE CLOTHING
    
    public func deleteClothingByID(clothingID: String) async throws {
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/\(clothingID)", method: .DELETE)
        _ = try await APIHandler.shared.executeRequest(request: request)
    }
}
