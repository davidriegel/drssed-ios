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
    //let userRepository: UserRepository
    
    public init(context: NSManagedObjectContext) {
        clothingRepository = ClothingRepository(context: context)
        outfitRepository = OutfitRepository(context: context)
        //userRepository = UserRepository(context: context)
    }

    public convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }

    //App-weite UseCases:
    /*
    func syncAll() async throws {
        try await clothingRepository.syncWithServerModels(/* ... */)
        try await outfitRepository.syncWithServerModels(/* ... */)
        try await userRepository.syncWithServerModels(/* ... */)
    }*/
}

