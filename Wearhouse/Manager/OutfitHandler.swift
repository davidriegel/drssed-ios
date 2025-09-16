//
//  OutfitHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 24.07.25.
//

import Foundation

final class OutfitHandler {
    
    init() {}
    
    // MARK: -- POST CREATE NEW OUTFIT
    
    func createNewOutfit(name: String, is_public: Bool, clothing_ids: [String], description: String?, tags: [String]?, seasons: [String]?) async throws -> Outfit {
        let outfitData = ["name": name, "is_public": is_public, "clothing_ids": clothing_ids, "description": description ?? "", "tags": tags ?? [], "seasons": seasons ?? []] as [String : Any]
        let uploadData = try JSONSerialization.data(withJSONObject: outfitData, options: [])
        
        let request = try await APIHandler.shared.createRequest(endpoint: "/users/me/outfits", method: .POST, body: uploadData)
        let outfitWrapper: OutfitWrapper = try await APIHandler.shared.executeRequestAndDecode(request: request)
        
        return outfitWrapper.outfit
    }
    
    // MARK: -- GET MY OUTFITS
    
    func getMyOutfits(limit: Int = 20, offset: Int = 0) async throws -> OutfitsWrapper {
        guard let userID = UserDefaults.standard.string(forKey: "user_id") else { throw AuthenticationError.userNotSignedIn }
        
        return try await getOutfitsByUserID(userID: userID)
    }
    
    // MARK: -- GET OUTFITS BY USER ID
    
    func getOutfitsByUserID(userID: String, limit: Int = 20, offset: Int = 0) async throws -> OutfitsWrapper {
        let request = try await APIHandler.shared.createRequest(endpoint: "/users/\(userID)/outfits?limit=\(limit)&offset=\(offset)", method: .GET)
        let outfitsWrapper: OutfitsWrapper = try await APIHandler.shared.executeRequestAndDecode(request: request)
        
        return outfitsWrapper
    }
}
