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
        
        if forceFull || shouldPerformFullSync(){
            await performFullSync()
        } else {
            await performIncrementalSync()
        }
    }
    
    private func shouldPerformFullSync() -> Bool {
        let clothingLastSync = SyncCursors.get(.clothing)
        let outfitLastSync = SyncCursors.get(.outfit)
        
        if clothingLastSync == nil || outfitLastSync == nil {
            return true
        }
        
        // if last sync is > 7 days ago
        if let lastSync = clothingLastSync,
           Date().timeIntervalSince(lastSync) > 7 * 24 * 60 * 60 {
            return true
        }
        
        return false
    }
    
    func clearSyncState() async {
        SyncCursors.resetAll()
        
        await clothesRepo.deleteAllLocal()
        await outfitRepo.deleteAllLocal()
    }
    
    private func performFullSync() async {
        do {
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: nil)
            await self.clothesRepo.syncWithServerModels(clothingSyncResponse.updated)
            SyncCursors.set(.clothing, to: clothingSyncResponse.serverTime)
            
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: nil)
            await self.outfitRepo.syncWithServerModels(outfitSyncResponse.updated)
            SyncCursors.set(.outfit, to: outfitSyncResponse.serverTime)
            
        } catch let error as AuthenticationError {
            ErrorHandler.handleSilently(error)
        } catch {
            ErrorHandler.handle(error)
        }
    }
    
    private func performIncrementalSync() async {
        do {
            let clothingLastSync = SyncCursors.get(.clothing)
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: clothingLastSync)
            await self.clothesRepo.applyServerSync(updated: clothingSyncResponse.updated, deleted: clothingSyncResponse.deleted)
            SyncCursors.set(.clothing, to: clothingSyncResponse.serverTime)
            
            let outfitLastSync = SyncCursors.get(.outfit)
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: outfitLastSync)
            await self.outfitRepo.applyServerSync(updated: outfitSyncResponse.updated, deleted: outfitSyncResponse.deleted)
            SyncCursors.set(.outfit, to: outfitSyncResponse.serverTime)
            
        } catch let error as AuthenticationError {
            ErrorHandler.handleSilently(error)
        } catch {
            ErrorHandler.handle(error)
        }
    }
}
