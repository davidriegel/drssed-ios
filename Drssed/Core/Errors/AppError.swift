//
//  AppError.swift
//  Drssed
//
//  Created by David Riegel on 17.09.25.
//

public enum AppError: Error {
    case api(APIError)
    case coreData(CoreDataError)
    case authentication(AuthenticationError)
    case custom(CustomError)
    case system(Error)
}
