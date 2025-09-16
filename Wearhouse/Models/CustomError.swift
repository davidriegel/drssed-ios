//
//  CustomError.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

public enum CustomError: Error {
    case formInvalid(field: String, suggestion: String)
    case valueTooLong(field: String, maxLength: Int)
    case valueTooShort(field: String, minLength: Int)
    case missingValue(field: String, suggestion: String?)
    case custom(String, suggestion: String?)
}
