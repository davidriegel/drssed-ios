//
//  ClothingLocal.swift
//  Drssed
//
//  Created by David Riegel on 16.09.25.
//


import Foundation
import CoreData

@objc(ClothingLocal)
class ClothingLocal: NSManagedObject {

    // MARK: - Core Data Attribute

    @NSManaged var category: String
    @NSManaged var color: String
    @NSManaged var createdAt: Date
    @NSManaged var id: String
    @NSManaged var imageID: String
    @NSManaged var isPublic: Bool
    @NSManaged var itemDescription: String
    @NSManaged var name: String
    @NSManaged var seasons: [String]
    @NSManaged var tags: [String]
    @NSManaged var updatedAt: Date
    @NSManaged var userID: String

    // MARK: - Convenience Initializer

    convenience init(
        context: NSManagedObjectContext,
        category: String,
        color: String,
        createdAt: Date = Date(),
        id: String,
        imageID: String,
        isPublic: Bool = false,
        itemDescription: String = "",
        name: String,
        seasons: [String] = [],
        tags: [String] = [],
        updatedAt: Date = Date(),
        userID: String
    ) {
        self.init(context: context)
        self.category = category
        self.color = color
        self.createdAt = createdAt
        self.id = id
        self.imageID = imageID
        self.isPublic = isPublic
        self.itemDescription = itemDescription
        self.name = name
        self.seasons = seasons
        self.tags = tags
        self.updatedAt = updatedAt
        self.userID = userID
    }
    
    func toDomain() -> Clothing {
        return Clothing(from: self)
    }
}

extension ClothingLocal {
    @nonobjc public class func fetchRequestTyped() -> NSFetchRequest<ClothingLocal> {
        return NSFetchRequest<ClothingLocal>(entityName: "ClothingLocal")
    }

    func update(from domainModel: Clothing) {
        self.id = domainModel.id
        self.name = domainModel.name
        self.imageID = domainModel.imageID
        self.category = domainModel.category.rawValue
        self.itemDescription = domainModel.description
        self.color = domainModel.color.hexString
        self.createdAt = domainModel.createdAt
        self.updatedAt = Date()
        self.isPublic = domainModel.isPublic
        self.seasons = domainModel.seasons.map { $0.rawValue }
        self.userID = domainModel.userID
        self.tags = domainModel.tags.map { $0.rawValue }
    }
}
