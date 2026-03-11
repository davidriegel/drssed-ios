//
//  ClothingRepository.swift
//  Drssed
//
//  Created by David Riegel on 16.09.25.
//


import CoreData

public final class ClothingRepository {
    private let context: NSManagedObjectContext
    private lazy var localDataSource = ClothingLocalDataSource(context: context)

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Server Sync (Hard replace)
    public func syncWithServerModels(_ apiModels: [ClothingAPI]) async {
        do {
            try await localDataSource.replaceAll(apiModels)
        } catch {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }
    
    // MARK: - Server Sync (Soft sync)
    
    public func applyServerSync(updated: [ClothingAPI], deleted: [String]) async {
        do {
            let models = updated.map(Clothing.init(from:))
            
            for item in models {
                try await localDataSource.upsert(item: item)
            }
            
            try await localDataSource.delete(ids: deleted)
            
        } catch {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }

    // MARK: - Upsert (overloads)
    public func addOrUpdateClothing(from apiModel: ClothingAPI) async {
        await addOrUpdateClothing(from: Clothing(from: apiModel))
    }

    @discardableResult
    public func addOrUpdateClothing(from domainModel: Clothing) async -> Bool {
        do {
            let existing = try await localDataSource.get(id: domainModel.id)

            let apiModel: ClothingAPI
            if let old = existing {
                apiModel = try await APIClient.shared.clothingHandler
                    .patchEditClothing(oldClothing: old, newClothing: domainModel)
            } else {
                apiModel = try await APIClient.shared.clothingHandler
                    .uploadClothing(domainModel)
            }

            let syncedDomainModel = apiModel.toDomain()
            await upsertClothing(syncedDomainModel)
            
            return true
        } catch {
            ErrorHandler.handle(error)
            return false
        }
    }

    // MARK: - Queries
    public func fetchClothes(
        filterSeasons: [Seasons]? = nil,
        filterTags: [Tags]? = nil,
        filterCategories: [ClothingCategories]? = nil,
        isPublic: Bool? = nil,
        sortBy: [NSSortDescriptor] = [NSSortDescriptor(key: "updatedAt", ascending: false)]
    ) async -> [Clothing] {
        do {
            return try await localDataSource.fetch(
                filterSeasons: filterSeasons,
                filterTags: filterTags,
                filterCategories: filterCategories,
                isPublic: isPublic,
                sortBy: sortBy
            )
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return []
        }
    }

    public func getClothing(with id: String) async -> Clothing? {
        do {
            return try await localDataSource.get(id: id)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return nil
        }
    }

    // MARK: - Delete
    @discardableResult
    public func deleteClothing(with id: String) async -> Bool {
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

    // MARK: - Private
    private func upsertClothing(_ domainModel: Clothing) async {
        do {
            try await localDataSource.upsert(item: domainModel)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }
}
