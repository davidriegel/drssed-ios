//
//  SyncManager.swift
//  Wearhouse
//
//  Created by David Riegel on 16.09.25.
//


class SyncManager {
    private let repo = ClothingRepository()
    
    public static let shared = SyncManager()
    
    private init() {}
    
    func syncWithServer() async {
        await pullFromServer()
        await pushLocalChanges()
    }
    
    
    private func pullFromServer() async {
        do {
            let clothesAPI = try await APIHandler.shared.clothingHandler.getMyClothing().clothing
            
            for apiItem in clothesAPI {
                self.repo.addOrUpdateClothing(from: apiItem)
            }
        } catch {
            //#warning("Pull failed")
            //#error("error.localizedDescription")
            print("Error while pulling from server: \(error)")
        }
    }
    
    private func pushLocalChanges() async {
        let pending = repo.fetchClothes().filter { $0.pendingSync }
        
        for item in pending {
            do {
                // uploadClothing ist async
                //try await APIHandler.shared.clothingHandler.
                
                // Markiere als synchronisiert
                //item.pendingSync = false
                //repo.save()
            } catch {
                print("Fehler beim Upload: \(error)")
            }
        }
    }
}
