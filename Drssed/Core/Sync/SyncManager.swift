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
    private let wearRepo = AppRepository.shared.wearRepository
    
    public static let shared = SyncManager()

    private var lastSuccessfulSync: Date?
    private var isSyncing: Bool = false

    private static let minimumSyncInterval: TimeInterval = 5 * 60

    private init() {}

    @discardableResult
    func syncWithServer(forceFull: Bool = false) async -> Bool {
        guard NetworkManager.shared.isReachable else { return false }

        let didSync: Bool

        if forceFull || shouldPerformFullSync(){
            didSync = await performFullSync()
        } else {
            didSync = await performIncrementalSync()
        }

        if didSync {
            lastSuccessfulSync = Date()

            await MainActor.run {
                NotificationCenter.default.post(name: .syncDidFinish, object: nil)
            }
        }

        return didSync
    }

    @discardableResult
    func syncIfStale() async -> Bool {
        guard !isSyncing else { return false }

        if let lastSuccessfulSync, Date().timeIntervalSince(lastSuccessfulSync) < Self.minimumSyncInterval {
            return false
        }

        isSyncing = true
        defer { isSyncing = false }

        return await syncWithServer()
    }

    private func shouldPerformFullSync() -> Bool {
        let clothingLastSync = SyncCursors.get(.clothing)
        let outfitLastSync = SyncCursors.get(.outfit)
        let wearLastSync = SyncCursors.get(.wear)

        if clothingLastSync == nil || outfitLastSync == nil || wearLastSync == nil {
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
        await wearRepo.deleteAllLocal()
    }
    
    private func performFullSync() async -> Bool {
        do {
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: nil)
            await self.clothesRepo.syncWithServerModels(clothingSyncResponse.updated)
            SyncCursors.set(.clothing, to: clothingSyncResponse.serverTime)
            
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: nil)
            await self.outfitRepo.syncWithServerModels(outfitSyncResponse.updated)
            SyncCursors.set(.outfit, to: outfitSyncResponse.serverTime)

            let wearSyncResponse = try await APIClient.shared.wearHandler.syncWears(updatedSince: nil)
            await self.wearRepo.syncWithServerModels(wearSyncResponse.updated)
            SyncCursors.set(.wear, to: wearSyncResponse.serverTime)
            
            return true
        } catch let error as AuthenticationError {
            ErrorHandler.handleSilently(error)
        } catch {
            ErrorHandler.handle(error)
        }
        
        return false
    }
    
    private func performIncrementalSync() async -> Bool {
        do {
            let clothingLastSync = SyncCursors.get(.clothing)
            let clothingSyncResponse = try await APIClient.shared.clothingHandler.syncClothes(updatedSince: clothingLastSync)
            await self.clothesRepo.applyServerSync(updated: clothingSyncResponse.updated, deleted: clothingSyncResponse.deleted)
            SyncCursors.set(.clothing, to: clothingSyncResponse.serverTime)
            
            let outfitLastSync = SyncCursors.get(.outfit)
            let outfitSyncResponse = try await APIClient.shared.outfitHandler.syncOutfits(updatedSince: outfitLastSync)
            await self.outfitRepo.applyServerSync(updated: outfitSyncResponse.updated, deleted: outfitSyncResponse.deleted)
            SyncCursors.set(.outfit, to: outfitSyncResponse.serverTime)

            let wearLastSync = SyncCursors.get(.wear)
            let wearSyncResponse = try await APIClient.shared.wearHandler.syncWears(updatedSince: wearLastSync)
            await self.wearRepo.applyServerSync(updated: wearSyncResponse.updated, deleted: wearSyncResponse.deleted)
            SyncCursors.set(.wear, to: wearSyncResponse.serverTime)

            return true
        } catch let error as AuthenticationError {
            ErrorHandler.handleSilently(error)
        } catch {
            ErrorHandler.handle(error)
        }
        
        return false
    }
}

extension Notification.Name {
    static let syncDidFinish = Notification.Name("syncDidFinish")
}
