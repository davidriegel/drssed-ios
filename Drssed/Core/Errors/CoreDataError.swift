//
//  CoreDataError.swift
//  Drssed
//
//  Created by David Riegel on 17.03.26.
//

import Foundation

public enum CoreDataError: Error {
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case contextNotAvailable
    case invalidManagedObject
}

extension CoreDataError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return String(format: NSLocalizedString("error.coreData.saveFailed", comment: ""), reason)
        case .fetchFailed(let reason):
            return String(format: NSLocalizedString("error.coreData.fetchFailed", comment: ""), reason)
        case .deleteFailed(let reason):
            return String(format: NSLocalizedString("error.coreData.deleteFailed", comment: ""), reason)
        case .contextNotAvailable:
            return String(localized: "error.coreData.contextNotAvailable")
        case .invalidManagedObject:
            return String(localized: "error.coreData.invalidManagedObject")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .deleteFailed:
            return String(localized: "error.coreData.saveDelete.suggestion")
        case .fetchFailed:
            return String(localized: "error.coreData.fetch.suggestion")
        case .contextNotAvailable, .invalidManagedObject:
            return String(localized: "error.coreData.critical.suggestion")
        }
    }
}

extension CoreDataError: Equatable {
    public static func == (lhs: CoreDataError, rhs: CoreDataError) -> Bool {
        switch (lhs, rhs) {
        case (.saveFailed(let a), .saveFailed(let b)),
             (.fetchFailed(let a), .fetchFailed(let b)),
             (.deleteFailed(let a), .deleteFailed(let b)):
            return a == b
        case (.contextNotAvailable, .contextNotAvailable),
             (.invalidManagedObject, .invalidManagedObject):
            return true
        default:
            return false
        }
    }
}
