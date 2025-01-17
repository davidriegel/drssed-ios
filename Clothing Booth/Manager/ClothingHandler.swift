//
//  ClothingHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 17.01.25.
//

import Foundation
import UIKit

class ClothingHandler {
    
    // MARK: -- POST REMOVE CLOTHING BACKGROUND
    
    func removeClothingBackground(from image: UIImage, _ fileExtension: String) async throws -> URL {
        let request = try await APIHandler.shared.createRequest(withImage: image, fileName: "clothingPicture.\(fileExtension)", endpoint: "/clothing/backgroundremover", method: .POST)
        let (data, response) = try await URLSession.shared.data(for: request)
    
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        
        let fetchedData = try JSONDecoder().decode(imageResponse.self, from: data)
        guard let url = URL(string: fetchedData.path, relativeTo: APIHandler.baseURL) else { throw URLError(.badURL) }
        return url
    }
    
    // MARK: -- POST UPLOAD CLOATHING
    
    func uploadClothing(with name: String, description: String, type: String, seasons: [String], tags: [String], imageURL: String, color: UIColor) async throws -> Clothing {
        let uploadDict = ["name": name, "description": description, "category": type.replacingOccurrences(of: "-", with: ""), "seasons": seasons, "tags": tags, "image_url": imageURL, "color": color.hexStringFromColor(color: color)] as [String : Any]
        let uploadData = try JSONSerialization.data(withJSONObject: uploadDict, options: [])
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/upload", method: .POST, body: uploadData)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
                
        let fetchedData = try JSONDecoder().decode(Clothing.self, from: data)
        return fetchedData
    }
    
    // MARK: -- GET CLOTHING LIST
    
    func getClothingList(limit: Int = 20, offset: Int = 0) async throws -> ClothingList {
        let request = try await APIHandler.shared.createRequest(endpoint: "/clothing/list?limit=\(limit)&offset=\(offset)", method: .GET)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        do {
            try APIHandler.shared.handleHTTPResponse(response as? HTTPURLResponse, data: data)
        } catch APIError.tooManyRequests {
            throw APIError.tooManyRequests
        } catch _ {
            return ClothingList(clothing: [], limit: limit, offset: offset)
        }
        
        let fetchedData = try JSONDecoder().decode(ClothingList.self, from: data)
        return fetchedData
    }
}
