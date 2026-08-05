//
//  DateDecoding.swift
//  Drssed
//
//  Created by David Riegel on 03.08.26.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {

    static let drssedISO8601 = JSONDecoder.DateDecodingStrategy.custom { decoder in
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        guard let date = DateParsing.date(from: text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an ISO 8601 date, got \(text)"
            )
        }

        return date
    }
}

enum DateParsing {

    private static let isoFormatters: [ISO8601DateFormatter] = {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        return [fractional, plain]
    }()

    private static let naiveFormatters: [DateFormatter] = {
        ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"].map { format in
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            return formatter
        }
    }()

    static func date(from text: String) -> Date? {
        for formatter in isoFormatters {
            if let date = formatter.date(from: text) { return date }
        }

        for formatter in naiveFormatters {
            if let date = formatter.date(from: text) { return date }
        }

        return nil
    }
}
