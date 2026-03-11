//
//  ClothingLocalDataSource.swift
//  Wearhouse
//
//  Created by David Riegel on 26.10.25.
//

import Foundation
import CoreData

public final class ClothingLocalDataSource {
    private let ctx: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.ctx = context
    }

    public func fetch(filterSeasons: [Seasons]? = nil, filterTags: [Tags]? = nil, filterCategories: [ClothingCategories]? = nil, isPublic: Bool? = nil, sortBy: [NSSortDescriptor] = [NSSortDescriptor(key: "updatedAt", ascending: false)]) async throws -> [Clothing] {
        
        let sortBlueprints: [(String, Bool)] = sortBy.map { ($0.key ?? "updatedAt", $0.ascending) }

        let result = try await self.ctx.perform { [sortBlueprints, ctx = self.ctx] in
            let req: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequestTyped()
            var predicates: [NSPredicate] = []

            if let seasons = filterSeasons, !seasons.isEmpty {
                let subs = seasons.map { NSPredicate(format: "ANY seasons == %@", $0.rawValue) }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: subs))
            }
            if let tags = filterTags, !tags.isEmpty {
                let subs = tags.map { NSPredicate(format: "ANY tags == %@", $0.rawValue) }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: subs))
            }
            if let categories = filterCategories, !categories.isEmpty {
                let subs = categories.map { NSPredicate(format: "category == %@", $0.rawValue) }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: subs))
            }
            if let isPublic {
                predicates.append(NSPredicate(format: "isPublic == %@", NSNumber(booleanLiteral: isPublic)))
            }

            if !predicates.isEmpty {
                req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            req.sortDescriptors = sortBlueprints.map { NSSortDescriptor(key: $0.0, ascending: $0.1) }

            let rows = try ctx.fetch(req)
            return rows.compactMap(Clothing.init(from:))
        }
        
        return result
    }
    
    public func fetch(ids: [String], sortBy: [NSSortDescriptor] = [NSSortDescriptor(key: "updatedAt", ascending: false)]) async throws -> [Clothing] {
        let sortBlueprints: [(String, Bool)] = sortBy.map { ($0.key ?? "updatedAt", $0.ascending) }
        
        let result = try await self.ctx.perform { [sortBlueprints, ctx = self.ctx] in
            let req: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequestTyped()
            let predicate = NSPredicate(format: "id IN %@", ids)
            
            req.predicate = predicate
            req.sortDescriptors = sortBlueprints.map { NSSortDescriptor(key: $0.0, ascending: $0.1) }
            
            let rows = try ctx.fetch(req)
            return rows.compactMap(Clothing.init(from:))
        }
        
        return result
    }
    
    public func get(id: String) async throws -> Clothing? {
        let result: Clothing? = try await self.ctx.perform { [ctx = self.ctx] () throws -> Clothing? in
            let req: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequestTyped()
            req.predicate = NSPredicate(format: "id == %@", id)
            
            guard let row = try ctx.fetch(req).first else {
                return nil
            }
            
            return Clothing(from: row)
        }
        
        return result
    }
    
    public func upsert(item: Clothing) async throws {
        try await self.ctx.perform { [ctx = self.ctx] in
            let req: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequestTyped()
            req.predicate = NSPredicate(format: "id == %@", item.id)
            req.fetchLimit = 1

            let mo = try ctx.fetch(req).first ?? ClothingLocal(context: ctx)
            mo.update(from: item)

            try ctx.saveIfNeeded()
        }
    }
    
    public func delete(ids: [String]) async throws {
        try await self.ctx.perform { [ctx = self.ctx] in
            guard !ids.isEmpty else { return }
            let fetch: NSFetchRequest<NSFetchRequestResult> = ClothingLocal.fetchRequest()
            fetch.predicate = NSPredicate(format: "id IN %@", ids)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetch)
            deleteReq.resultType = .resultTypeObjectIDs
            if let result = try ctx.execute(deleteReq) as? NSBatchDeleteResult,
               let deleted = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: deleted]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [ctx])
            }
        }
    }
    
    /// Hard-reset (Synchronize with Server)
    public func replaceAll(_ newValues: [ClothingAPI]) async throws {
        let incoming: [Clothing] = newValues.map(Clothing.init(from:))
        let ids = Set(incoming.map { $0.id })

        try await self.ctx.perform { [ctx = self.ctx] in
            let fetch: NSFetchRequest<NSFetchRequestResult> = ClothingLocal.fetchRequest()
            fetch.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetch)
            deleteReq.resultType = .resultTypeObjectIDs
            if let result = try ctx.execute(deleteReq) as? NSBatchDeleteResult,
               let deleted = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: deleted]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [ctx])
            }

            for item in incoming {
                let req: NSFetchRequest<ClothingLocal> = ClothingLocal.fetchRequestTyped()
                req.predicate = NSPredicate(format: "id == %@", item.id)
                req.fetchLimit = 1
                let mo = try ctx.fetch(req).first ?? ClothingLocal(context: ctx)
                mo.update(from: item)
            }

            try ctx.saveIfNeeded()
        }
    }
}
