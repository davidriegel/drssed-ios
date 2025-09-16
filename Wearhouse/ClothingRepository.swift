//
//  ClothingRepository.swift
//  Wearhouse
//
//  Created by David Riegel on 16.09.25.
//


import CoreData

class ClothingRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func addOrUpdateClothing(from apiModel: ClothingAPI) {
        let request: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", apiModel.clothing_id as CVarArg)
        
        let item = (try? context.fetch(request))?.first ?? ClothingLocal(context: context)
        item.id = apiModel.clothing_id
        item.name = apiModel.name
        item.imageID = apiModel.image_id
        item.category = apiModel.category.rawValue
        item.itemDescription = apiModel.description
        item.color = apiModel.color
        item.createdAt = apiModel.created_at
        item.updatedAt = Date()
        item.is_public = apiModel.is_public
        item.pendingSync = false
        item.seasons = apiModel.seasons as NSObject
        item.tags = apiModel.tags as NSObject
        save()
    }
    
    func fetchClothes(filterSeasons: [Seasons]? = nil, filterTags: [Tags]? = nil, isPublic: Bool? = nil, sortBy: [NSSortDescriptor]? = [NSSortDescriptor(key: "updatedAt", ascending: false)]) -> [ClothingLocal] {
        let request: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequest()
        var predicates: [NSPredicate] = []
        
        if let seasons = filterSeasons, !seasons.isEmpty {
            let seasonPredicates = seasons.map { NSPredicate(format: "ANY seasons == %@", $0.rawValue) }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: seasonPredicates))
        }
        
        if let tags = filterTags, !tags.isEmpty {
            let tagPredicates = tags.map { NSPredicate(format: "ANY tags == %@", $0.rawValue) }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = sortBy
        return (try? context.fetch(request)) ?? []
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Core Data Save-Error: \(error)")
        }
    }
}
