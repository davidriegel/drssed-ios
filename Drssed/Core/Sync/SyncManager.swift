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
    
    func syncWithServer(forceFull: Bool = false) async {
        guard NetworkManager.shared.isReachable else { return }
        
        if forceFull {
            await performFullSync()
        } else {
            await performIncrementalSync()
        }
    }
    
    func clearSyncState() async {
        UserDefaults.standard.removeObject(forKey: "clothing_last_sync")
        UserDefaults.standard.removeObject(forKey: "outfit_last_sync")
        
        await clothesRepo.deleteAllLocal()
        await outfitRepo.deleteAllLocal()
    }
    
    private func performFullSync() async {
        do {
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: nil)
            await self.clothesRepo.syncWithServerModels(clothingSyncResponse.updated)
            UserDefaults.standard.set(clothingSyncResponse.serverTime, forKey: "clothing_last_sync")
            
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: nil)
            await self.outfitRepo.syncWithServerModels(outfitSyncResponse.updated)
            UserDefaults.standard.set(outfitSyncResponse.serverTime, forKey: "outfit_last_sync")
            
        } catch let error as AuthenticationError {
            ErrorHandler.handleSilently(error)
        } catch {
            ErrorHandler.handle(error)
        }
    }
    
    private func performIncrementalSync() async {
        do {
            let clothingLastSync = UserDefaults.standard.object(forKey: "clothing_last_sync") as? Date
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: clothingLastSync)
            await self.clothesRepo.applyServerSync(updated: clothingSyncResponse.updated, deleted: clothingSyncResponse.deleted)
            UserDefaults.standard.set(clothingSyncResponse.serverTime, forKey: "clothing_last_sync")
            
            let outfitLastSync = UserDefaults.standard.object(forKey: "outfit_last_sync") as? Date
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: outfitLastSync)
            await self.outfitRepo.applyServerSync(updated: outfitSyncResponse.updated, deleted: outfitSyncResponse.deleted)
            UserDefaults.standard.set(outfitSyncResponse.serverTime, forKey: "outfit_last_sync")
            
        } catch let error as AuthenticationError {
            ErrorHandler.handleSilently(error)
        } catch {
            ErrorHandler.handle(error)
        }
    }
}
