//
//  CustomError.swift
//  Drssed
//
//  Created by David Riegel on 23.04.25.
//

import Foundation

public enum CustomError: Error {
    case formInvalid(field: String, suggestion: String? = nil)
    case valueTooLong(field: String, maxLength: Int)
    case valueTooShort(field: String, minLength: Int)
    case missingValue(field: String, suggestion: String? = nil)
    case custom(message: String, suggestion: String? = nil)
}

extension CustomError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .formInvalid(let field, _):
            return String(format: NSLocalizedString("error.custom.formInvalid.description", comment: ""), field)
        case .valueTooLong(let field, let maxLength):
            return String(format: NSLocalizedString("error.custom.valueTooLong.description", comment: ""), field, maxLength)
        case .valueTooShort(let field, let minLength):
            return String(format: NSLocalizedString("error.custom.valueTooShort.description", comment: ""), field, minLength)
        case .missingValue(let field, _):
            return String(format: NSLocalizedString("error.custom.missingValue.description", comment: ""), field)
        case .custom(let message, _):
            return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .formInvalid(_, let suggestion),
             .missingValue(_, let suggestion),
             .custom(_, let suggestion):
            return suggestion
        case .valueTooLong, .valueTooShort:
            return nil
        }
    }
}
