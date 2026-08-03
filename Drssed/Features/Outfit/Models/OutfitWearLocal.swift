//
//  OutfitWearLocal.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import Foundation
import CoreData

@objc(OutfitWearLocal)
class OutfitWearLocal: NSManagedObject {

    // MARK: - Core Data Attribute

    @NSManaged var id: String
    @NSManaged var userID: String
    @NSManaged var outfitID: String
    @NSManaged var wornOn: Date
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var feelsLike: NSNumber?
    @NSManaged var temperature: NSNumber?
    @NSManaged var weather: String?
    @NSManaged var occasion: String?
    @NSManaged var rating: NSNumber?
    @NSManaged var note: String?
    @NSManaged var clothingIDs: [String]

    func toDomain() -> OutfitWear {
        return OutfitWear(from: self)
    }
}

extension OutfitWearLocal {
    @nonobjc public class func fetchRequestTyped() -> NSFetchRequest<OutfitWearLocal> {
        return NSFetchRequest<OutfitWearLocal>(entityName: "OutfitWearLocal")
    }

    func update(from domainModel: OutfitWear) {
        self.id = domainModel.id
        self.userID = domainModel.userID
        self.outfitID = domainModel.outfitID
        self.wornOn = domainModel.wornOn
        self.createdAt = domainModel.createdAt
        self.updatedAt = domainModel.updatedAt
        self.feelsLike = domainModel.feelsLike.map(NSNumber.init(value:))
        self.temperature = domainModel.temperature.map(NSNumber.init(value:))
        self.weather = domainModel.weather?.rawValue
        self.occasion = domainModel.occasion?.rawValue
        self.rating = domainModel.rating.map(NSNumber.init(value:))
        self.note = domainModel.note
        self.clothingIDs = domainModel.clothingIDs
    }
}
