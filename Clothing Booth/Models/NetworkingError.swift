//
//  NetworkingError.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import Foundation

public enum NetworkingError: Error {
    case badRequest
    case rateLimiting
    case notFound
    case unauthorized
    case conflict
}
