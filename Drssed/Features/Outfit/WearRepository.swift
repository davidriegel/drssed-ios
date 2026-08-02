//
//  WearRepository.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import CoreData

public final class WearRepository {
    private let context: NSManagedObjectContext
    private lazy var localDataSource = WearLocalDataSource(context: context)

    init(context: NSManagedObjectContext = PersistenceController.shared.backgroundContext) {
        self.context = context
    }

    // MARK: - Server Sync (Hard replace)
    public func syncWithServerModels(_ apiModels: [OutfitWearAPI]) async {
        do {
            try await localDataSource.replaceAll(apiModels)
        } catch {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }

    // MARK: - Server Sync (Soft sync)
    public func applyServerSync(updated: [OutfitWearAPI], deleted: [String]) async {
        do {
            try await localDataSource.upsert(items: updated.map(OutfitWear.init(from:)))
            try await localDataSource.delete(ids: deleted)

        } catch {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }

    // MARK: - Queries
    public func fetchWears(outfitID: String? = nil, limit: Int? = nil) async -> [OutfitWear] {
        do {
            return try await localDataSource.fetch(outfitID: outfitID, limit: limit)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return []
        }
    }

    /// All entries worn within `[from, to)`, newest first.
    public func fetchWears(from: Date, to: Date) async -> [OutfitWear] {
        do {
            return try await localDataSource.fetch(from: from, to: to)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return []
        }
    }

    public func getWear(with id: String) async -> OutfitWear? {
        do {
            return try await localDataSource.get(id: id)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return nil
        }
    }

    /// The entry of an outfit for a given day, if it was worn then.
    public func getWear(forOutfit outfitID: String, on date: Date = Date()) async -> OutfitWear? {
        do {
            return try await localDataSource.get(outfitID: outfitID, on: date)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return nil
        }
    }

    public func wearCount(forOutfit outfitID: String) async -> Int {
        do {
            return try await localDataSource.count(outfitID: outfitID)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.fetchFailed(error.localizedDescription)))
            return 0
        }
    }

    // MARK: - Wear
    public func logWear(
        outfitID: String,
        wornOn: Date? = nil,
        feelsLike: Double? = nil,
        temperature: Double? = nil,
        weather: WeatherCondition? = nil,
        occasion: WearOccasion? = nil,
        rating: Int? = nil,
        note: String? = nil
    ) async -> OutfitWear? {
        do {
            let apiModel = try await APIClient.shared.wearHandler.logWear(
                outfitID: outfitID,
                wornOn: wornOn,
                feelsLike: feelsLike,
                temperature: temperature,
                weather: weather,
                occasion: occasion,
                rating: rating,
                note: note
            )

            let domainModel = apiModel.toDomain()
            await upsertWear(domainModel)

            return domainModel
        } catch {
            ErrorHandler.handle(error)
            return nil
        }
    }

    /// Logs a wear for right now and attaches the current weather when it can be resolved.
    public func logWearNow(outfitID: String) async -> OutfitWear? {
        let snapshot = await WeatherProvider.shared.currentWeather()

        return await logWear(
            outfitID: outfitID,
            feelsLike: snapshot?.feelsLike,
            temperature: snapshot?.temperature,
            weather: snapshot?.condition
        )
    }

    // MARK: - Edit a wear
    public func updateWear(from oldDomainModel: OutfitWear, to newDomainModel: OutfitWear) async -> OutfitWear? {
        do {
            let apiModel = try await APIClient.shared.wearHandler.patchWear(oldDomainModel, newDomainModel)

            let domainModel = apiModel.toDomain()
            await upsertWear(domainModel)

            return domainModel
        } catch {
            ErrorHandler.handle(error)
            return nil
        }
    }

    // MARK: - Unwear
    @discardableResult
    public func deleteWear(with id: String) async -> Bool {
        do {
            try await APIClient.shared.wearHandler.deleteWearByID(wearID: id)
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
    private func upsertWear(_ domainModel: OutfitWear) async {
        do {
            try await localDataSource.upsert(item: domainModel)
        } catch let error as NSError {
            ErrorHandler.handle(AppError.coreData(.saveFailed(error.localizedDescription)))
        }
    }
}
