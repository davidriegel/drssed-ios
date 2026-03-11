//
//  OutfitLocal.swift
//  Wearhouse
//
//  Created by David Riegel on 02.10.25.
//

import Foundation
import CoreData

@objc(OutfitLocal)
class OutfitLocal: NSManagedObject {

    // MARK: - Core Data Attribute

    @NSManaged var createdAt: Date
    @NSManaged var id: String
    @NSManaged var imageID: String
    @NSManaged var isPublic: Bool
    @NSManaged var isFavorite: Bool
    @NSManaged var itemDescription: String
    @NSManaged var name: String
    @NSManaged var seasons: [String]
    @NSManaged var tags: [String]
    @NSManaged var updatedAt: Date
    @NSManaged var userID: String
    @NSManaged var sceneData: Data

    // MARK: - Convenience Initializer

    convenience init(
        context: NSManagedObjectContext,
        createdAt: Date = Date(),
        id: String,
        imageID: String,
        isPublic: Bool = false,
        isFavorite: Bool = false,
        itemDescription: String = "",
        name: String,
        seasons: [String] = [],
        tags: [String] = [],
        updatedAt: Date = Date(),
        scene: [CanvasPlacement] = [],
        userID: String
    ) {
        self.init(context: context)
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.id = id
        self.imageID = imageID
        self.isPublic = isPublic
        self.itemDescription = itemDescription
        self.name = name
        self.seasons = seasons
        self.tags = tags
        self.scene = scene
        self.updatedAt = updatedAt
        self.userID = userID
    }
    
    func toDomain() -> Outfit {
        return Outfit(from: self)
    }
}

extension OutfitLocal {
    @nonobjc public class func fetchRequestTyped() -> NSFetchRequest<OutfitLocal> {
        return NSFetchRequest<OutfitLocal>(entityName: "OutfitLocal")
    }
    
    func update(from domainModel: Outfit) {
        self.id = domainModel.id
        self.name = domainModel.name
        self.imageID = domainModel.imageID
        self.itemDescription = domainModel.description
        self.createdAt = domainModel.createdAt
        self.updatedAt = Date()
        self.isFavorite = domainModel.isFavorite
        self.isPublic = domainModel.isPublic
        self.seasons = domainModel.seasons.map { $0.rawValue }
        self.userID = domainModel.userID
        self.tags = domainModel.tags.map { $0.rawValue }
        self.scene = domainModel.scene
    }
}

extension OutfitLocal {
    var scene: [CanvasPlacement] {
        get {
            (try? JSONDecoder().decode([CanvasPlacement].self, from: sceneData)) ?? []
        }
        set {
            sceneData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
