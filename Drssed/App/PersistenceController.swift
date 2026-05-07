//
//  PersistenceController.swift
//  Drssed
//
//  Created by David Riegel on 16.09.25.
//

import CoreData
import os

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LocalData")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        else {
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }
        
        loadStores(recoveryAttempted: false)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private func loadStores(recoveryAttempted: Bool) {
        container.loadPersistentStores { [container] storeDescription, error in
            guard let error = error as NSError? else { return }
            
            Logger.persistence.error("Core Data loading error: \(error.domain):\(error.code) for user \(error.userInfo)")
            
            guard !recoveryAttempted, isRecoverable(error) else {
                #if DEBUG
                fatalError("CoreData unrecoverable: \(error)")
                #else
                return
                #endif
            }
            
            destroyStore(for: storeDescription, in: container)
            loadStores(recoveryAttempted: true)
        }
    }
    
    private func isRecoverable(_ error: NSError) -> Bool {
        guard error.domain == NSCocoaErrorDomain else { return false }
        let recoverableCodes: Set<Int> = [
            NSPersistentStoreIncompatibleVersionHashError,
            NSMigrationError,
            NSMigrationMissingSourceModelError,
            NSMigrationMissingMappingModelError,
            NSPersistentStoreIncompatibleSchemaError,
        ]
        return recoverableCodes.contains(error.code)
    }
    
    private func destroyStore(for description: NSPersistentStoreDescription, in container: NSPersistentContainer) {
        SyncCursors.resetAll()
        
        guard let url = description.url, url.path != "/dev/null" else { return }
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: description.type, options: description.options)
            
            Logger.persistence.info("Successfully deleted a corrupted store at \(url.lastPathComponent), will re-sync")
        } catch {
            Logger.persistence.error("Failed to delete a corrupted store: \(error, privacy: .public)")
        }
    }
}
