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
    
    public init(context: NSManagedObjectContext) {
        clothingRepository = ClothingRepository(context: context)
        outfitRepository = OutfitRepository(context: context)
    }

    public convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }
}
