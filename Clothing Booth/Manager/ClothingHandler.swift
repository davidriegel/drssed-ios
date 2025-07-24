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
    
    public func removeClothingBackground(from image: UIImage, _ fileExtension: String) async throws -> URL {
        let request = try await APIHandler.shared.createRequest(withImage: image, fileName: "clothingPicture.\(fileExtension)", endpoint: "/images/preview", method: .POST)
        let (data, _) = try await APIHandler.shared.executeRequest(request: request)
        
        let fetchedData = try JSONDecoder().decode(imageResponse.self, from: data)
        guard let url = URL(string: fetchedData.image_url, relativeTo: APIHandler.baseURL) else { throw URLError(.badURL) }
        return url
    }
    
    // MARK: -- POST UPLOAD CLOATHING
    
    public func uploadClothing(with name: String, description: String, type: String, seasons: [String], tags: [String], imageURL: String, color: UIColor) async throws -> Clothing {
        let uploadDict = ["name": name, "description": description, "category": type.replacingOccurrences(of: "-", with: ""), "seasons": seasons, "tags": tags, "image_url": imageURL, "color": color.hexStringFromColor(color: color)] as [String : Any]
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/", method: .POST, body: uploadData)
        let (data, _) = try await APIHandler.shared.executeRequest(request: request)
                
        let fetchedData = try JSONDecoder().decode(Clothing.self, from: data)
        return fetchedData
    }
    
    // MARK: -- GET CLOTHING LIST
    
    public func getClothingList(userID: String, limit: Int = 20, offset: Int = 0) async throws -> ClothingList {
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/list/\(userID)?limit=\(limit)&offset=\(offset)", method: .GET, authentication: true)
        let (data, _) = try await APIHandler.shared.executeRequest(request: request)
        
        let fetchedData = try JSONDecoder().decode(ClothingList.self, from: data)
        return fetchedData
    }
    
    // MARK: -- PUT EDIT CLOTHING
    
    public func putEditClothing(clothing: Clothing) async throws {
        let uploadData = try JSONEncoder().encode(clothing)
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/\(clothing.clothing_id)", method: .PUT, body: uploadData)
        _ = try await APIHandler.shared.executeRequest(request: request)
    }
    
    // MARK: -- DELETE CLOTHING
    
    public func deleteClothing(clothing: Clothing) async throws {
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/\(clothing.clothing_id)", method: .DELETE)
        _ = try await APIHandler.shared.executeRequest(request: request)
    }
}
