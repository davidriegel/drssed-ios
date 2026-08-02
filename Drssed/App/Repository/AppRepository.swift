//
//  AppRepository.swift
//  Drssed
//
//  Created by David Riegel on 24.10.25.
//

import CoreData

final public class AppRepository {
    public static let shared = AppRepository()
    public let clothingRepository: ClothingRepository
    public let outfitRepository: OutfitRepository
    public let wearRepository: WearRepository
    public let userRepository: UserRepository

    private init(context: NSManagedObjectContext) {
        clothingRepository = ClothingRepository(context: context)
        outfitRepository = OutfitRepository(context: context)
        wearRepository = WearRepository(context: context)
        userRepository = UserRepository.shared
    }

    private convenience init() {
        self.init(context: PersistenceController.shared.backgroundContext)
    }
}
