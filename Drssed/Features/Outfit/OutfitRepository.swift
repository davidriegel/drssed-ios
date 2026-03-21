//
//  ClothingRepository 2.swift
//  Drssed
//
//  Created by David Riegel on 02.10.25.
//

import CoreData

public final class OutfitRepository {
    private let context: NSManagedObjectContext
    private lazy var localDataSource = OutfitLocalDataSource(context: context)

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Server Sync (Hard replace)
    public func syncWithServerModels(_ apiModels: [OutfitAPI]) async {
        do {
            try await localDataSource.replaceAll(apiModels)
        } catch {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }
    
    public func applyServerSync(updated: [OutfitAPI], deleted: [String]) async {
        do {
            let models = updated.map(Outfit.init(from:))
            
            for item in models {
                try await localDataSource.upsert(item: item)
            }
            
            try await localDataSource.delete(ids: deleted)
            
        } catch {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }

    // MARK: - Upsert (overloads)
    public func addOrUpdateOutfit(from apiModel: OutfitAPI) async {
        await addOrUpdateOutfit(from: Outfit(from: apiModel))
    }

    @discardableResult
    public func addOrUpdateOutfit(
        from domainModel: Outfit
    ) async -> Bool {
        do {
            let existing = try await localDataSource.get(id: domainModel.id)

            let apiModel: OutfitAPI
            if let old = existing {
                apiModel = old.toAPI()
                //apiModel = try await APIHandler.shared.outfitHandler.patchEditClothing(oldClothing: old, newClothing: domainModel)
                //apiModel = try await APIHandler.shared.outfitHandler.getMyOutfits().items.first!
            } else {
                apiModel = try await APIClient.shared.outfitHandler.createNewOutfit(
                    domainModel
                )
            }

            let syncedDomainModel = apiModel.toDomain()
            await upsertOutfit(syncedDomainModel)
            
            return true
        } catch {
            ErrorHandler.handle(error)
            return false
        }
    }

    // MARK: - Queries
    public func fetchOutfits(
        filterSeasons: [Seasons]? = nil,
        filterTags: [Tags]? = nil,
        isPublic: Bool? = nil,
        isFavorite: Bool? = nil,
        sortBy: [NSSortDescriptor] = [NSSortDescriptor(key: "updatedAt", ascending: false)]
    ) async -> [Outfit] {
        do {
            return try await localDataSource.fetch(
                filterSeasons: filterSeasons,
                filterTags: filterTags,
                isPublic: isPublic,
                isFavorite: isFavorite,
                sortBy: sortBy
            )
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return []
        }
    }

    public func getOutfit(with id: String) async -> Outfit? {
        do {
            return try await localDataSource.get(id: id)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return nil
        }
    }
    
    // MARK: - Delete
    @discardableResult
    public func deleteOutfit(with id: String) async -> Bool {
        do {
            try await APIClient.shared.clothingHandler.deleteClothingByID(clothingID: id)
            try await localDataSource.delete(ids: [id])
            return true
        } catch let error as APIError {
            ErrorHandler.handle(error)
            return false
        } catch let error {
            ErrorHandler.handle(AppError.coreData(.deleteFailed(error.localizedDescription)))
            return false
        }
    }
    
    public func deleteAllLocal() async {
        do {
            try await localDataSource.deleteAll()
        } catch {
            ErrorHandler.handle(AppError.coreData(.deleteFailed(error.localizedDescription)))
        }
    }

    // MARK: - Private
    private func upsertOutfit(_ domainModel: Outfit) async {
        do {
            try await localDataSource.upsert(item: domainModel)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }
}
