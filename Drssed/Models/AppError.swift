//
//  AppError.swift
//  Drssed
//
//  Created by David Riegel on 17.09.25.
//

public enum AppError: Error {
    case api(APIError)
    case coreData(CoreDataError)
    case system(Error)
}

public enum CoreDataError: Error {
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
}
