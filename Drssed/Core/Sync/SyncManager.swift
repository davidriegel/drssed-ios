//
//  SyncManager.swift
//  Drssed
//
//  Created by David Riegel on 16.09.25.
//

import Foundation

final class SyncManager {
    private let clothesRepo = AppRepository.shared.clothingRepository
    private let outfitRepo = AppRepository.shared.outfitRepository
    
    public static let shared = SyncManager()
    
    private init() {}
    
    func syncWithServer() async {
        guard NetworkManager.shared.isReachable else {
            print("No connection to server, skipping sync")
            return
        }
        
        await pullFromServer()
    }
    
    func clearSyncState() async {
        UserDefaults.standard.removeObject(forKey: "clothing_last_sync")
        UserDefaults.standard.removeObject(forKey: "outfit_last_sync")
        
        await clothesRepo.deleteAllLocal()
        await outfitRepo.deleteAllLocal()
    }
    
    private func pullFromServer() async {
        do {
            let clothingLastSync = UserDefaults.standard.object(forKey: "clothing_last_sync") as? Date
                        
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: clothingLastSync)
                        
            await self.clothesRepo.applyServerSync(updated: clothingSyncResponse.updated, deleted: clothingSyncResponse.deleted)
            
            UserDefaults.standard.set(clothingSyncResponse.serverTime, forKey: "clothing_last_sync")
            
            let outfitLastSync = UserDefaults.standard.object(forKey: "outfit_last_sync") as? Date
                        
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: outfitLastSync)
                        
            await self.outfitRepo.applyServerSync(updated: outfitSyncResponse.updated, deleted: outfitSyncResponse.deleted)
            
            UserDefaults.standard.set(outfitSyncResponse.serverTime, forKey: "outfit_last_sync")
        } catch AuthenticationError.userNotSignedIn {
            print("User not signed in skipping sync")
        } catch {
            ErrorHandler.handle(error)
            print("Error while pulling from server: \(error)")
        }
    }
}
