//
//  ClothingRepository.swift
//  Drssed
//
//  Created by David Riegel on 16.09.25.
//

import CoreData
import UIKit
import SDWebImage

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
    
    public func getClothingImage(with id: String) async -> UIImage? {
        do {
            let clothing = try await localDataSource.get(id: id)
            
            guard let url = URL(string: clothing?.imageID ?? "", relativeTo: APIClient.clothingImagesURL) else {
                    return nil
            }
            
            return await withCheckedContinuation { continuation in
                SDWebImageManager.shared.loadImage(
                    with: url,
                    options: [],
                    progress: nil
                ) { image, _, error, _, _, _ in
                    if let error = error {
                        ErrorHandler.handleSilently(error)
                    }
                    continuation.resume(returning: image)
                }
            }
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return nil
        }
    }
    
    public func getClothingImages(with ids: [String]) async -> [String: UIImage] {
        await withTaskGroup(of: (String, UIImage?).self) { group in
            var images: [String: UIImage] = [:]
            
            for id in ids {
                group.addTask {
                    let image = await self.getClothingImage(with: id)
                    return (id, image)
                }
            }
            
            for await (id, image) in group {
                if let image = image {
                    images[id] = image
                }
            }
            
            return images
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
    
    public func deleteAllLocal() async {
        do {
            try await localDataSource.deleteAll()
        } catch {
            ErrorHandler.handle(AppError.coreData(.deleteFailed(error.localizedDescription)))
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
