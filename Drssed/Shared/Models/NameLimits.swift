//
//  NameLimits.swift
//  Drssed
//
//  Created by David Riegel on 04.09.26.
//

import Foundation

/// What the server accepts as a name for a clothing piece or an outfit. Kept in one
/// place so a form rejects a name the upload would only fail on later, and so all
/// four save paths word it the same way.
enum NameLimits {
    static let minimum = 3
    static let maximum = 50

    /// The name to send, trimmed and capped.
    /// - Throws: A `CustomError` naming what the user has to correct.
    static func validated(_ raw: String?) throws -> String {
        let field = String(localized: "common.name.title")
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !trimmed.isEmpty else {
            throw CustomError.missingValue(field: field)
        }

        guard trimmed.count >= minimum else {
            throw CustomError.valueTooShort(field: field, minLength: minimum)
        }

        return String(trimmed.prefix(maximum))
    }
}
