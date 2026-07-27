//
//  WearLocalDataSource.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import Foundation
import CoreData

public final class WearLocalDataSource {
    private let ctx: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.ctx = context
    }

    public func fetch(outfitID: String? = nil, limit: Int? = nil, sortBy: [NSSortDescriptor] = [NSSortDescriptor(key: "wornOn", ascending: false)]) async throws -> [OutfitWear] {
        let sortBlueprints: [(String, Bool)] = sortBy.map { ($0.key ?? "wornOn", $0.ascending) }

        let result = try await self.ctx.perform { [sortBlueprints, ctx = self.ctx] in
            let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()

            if let outfitID {
                req.predicate = NSPredicate(format: "outfitID == %@", outfitID)
            }

            if let limit {
                req.fetchLimit = limit
            }

            req.sortDescriptors = sortBlueprints.map { NSSortDescriptor(key: $0.0, ascending: $0.1) }

            let rows = try ctx.fetch(req)
            return rows.compactMap(OutfitWear.init(from:))
        }

        return result
    }

    /// All entries worn within `[from, to)`, newest first.
    public func fetch(from: Date, to: Date, sortBy: [NSSortDescriptor] = [NSSortDescriptor(key: "wornOn", ascending: false)]) async throws -> [OutfitWear] {
        let sortBlueprints: [(String, Bool)] = sortBy.map { ($0.key ?? "wornOn", $0.ascending) }

        let result = try await self.ctx.perform { [sortBlueprints, ctx = self.ctx] in
            let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()
            req.predicate = NSPredicate(format: "wornOn >= %@ AND wornOn < %@", from as NSDate, to as NSDate)
            req.sortDescriptors = sortBlueprints.map { NSSortDescriptor(key: $0.0, ascending: $0.1) }

            let rows = try ctx.fetch(req)
            return rows.compactMap(OutfitWear.init(from:))
        }

        return result
    }

    public func get(id: String) async throws -> OutfitWear? {
        let result: OutfitWear? = try await self.ctx.perform { [ctx = self.ctx] () throws -> OutfitWear? in
            let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()
            req.predicate = NSPredicate(format: "id == %@", id)
            req.fetchLimit = 1

            guard let row = try ctx.fetch(req).first else {
                return nil
            }

            return OutfitWear(from: row)
        }

        return result
    }

    /// Returns the entry of an outfit that falls on the same day as `date`, if there is one.
    public func get(outfitID: String, on date: Date, calendar: Calendar = .current) async throws -> OutfitWear? {
        let dayStart = calendar.startOfDay(for: date)

        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return nil
        }

        let result: OutfitWear? = try await self.ctx.perform { [ctx = self.ctx] () throws -> OutfitWear? in
            let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()
            req.predicate = NSPredicate(
                format: "outfitID == %@ AND wornOn >= %@ AND wornOn < %@",
                outfitID, dayStart as NSDate, dayEnd as NSDate
            )
            req.fetchLimit = 1

            guard let row = try ctx.fetch(req).first else {
                return nil
            }

            return OutfitWear(from: row)
        }

        return result
    }

    public func count(outfitID: String) async throws -> Int {
        let result = try await self.ctx.perform { [ctx = self.ctx] in
            let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()
            req.predicate = NSPredicate(format: "outfitID == %@", outfitID)

            return try ctx.count(for: req)
        }

        return result
    }

    public func upsert(item: OutfitWear) async throws {
        try await self.ctx.perform { [ctx = self.ctx] in
            let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()
            req.predicate = NSPredicate(format: "id == %@", item.id)
            req.fetchLimit = 1

            let mo = try ctx.fetch(req).first ?? OutfitWearLocal(context: ctx)
            mo.update(from: item)

            try ctx.saveIfNeeded()
        }
    }

    public func delete(ids: [String]) async throws {
        try await self.ctx.perform { [ctx = self.ctx] in
            guard !ids.isEmpty else { return }
            let fetch: NSFetchRequest<NSFetchRequestResult> = OutfitWearLocal.fetchRequest()
            fetch.predicate = NSPredicate(format: "id IN %@", ids)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetch)
            deleteReq.resultType = .resultTypeObjectIDs
            if let result = try ctx.execute(deleteReq) as? NSBatchDeleteResult,
               let deleted = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: deleted]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [ctx])
            }

            try ctx.saveIfNeeded()
        }
    }

    /// Hard-reset (Synchronize with Server)
    public func replaceAll(_ newValues: [OutfitWearAPI]) async throws {
        let incoming: [OutfitWear] = newValues.map(OutfitWear.init(from:))
        let ids = Set(incoming.map { $0.id })

        try await self.ctx.perform { [ctx = self.ctx] in
            let fetch: NSFetchRequest<NSFetchRequestResult> = OutfitWearLocal.fetchRequest()
            fetch.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetch)
            deleteReq.resultType = .resultTypeObjectIDs
            if let result = try ctx.execute(deleteReq) as? NSBatchDeleteResult,
               let deleted = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: deleted]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [ctx])
            }

            for item in incoming {
                let req: NSFetchRequest<OutfitWearLocal> = OutfitWearLocal.fetchRequestTyped()
                req.predicate = NSPredicate(format: "id == %@", item.id)
                req.fetchLimit = 1
                let mo = try ctx.fetch(req).first ?? OutfitWearLocal(context: ctx)
                mo.update(from: item)
            }

            try ctx.saveIfNeeded()
        }
    }

    func deleteAll() async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = OutfitWearLocal.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try ctx.execute(deleteRequest)
        try ctx.saveIfNeeded()
    }
}
