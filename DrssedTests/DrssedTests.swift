//
//  DrssedTests.swift
//  DrssedTests
//
//  Created by David Riegel on 06.05.24.
//

import XCTest
@testable import Drssed

final class EmailValidationTests: XCTestCase {

    func testAcceptsOrdinaryAddresses() {
        XCTAssertTrue("david@drssed.app".isValidEmail)
        XCTAssertTrue("first.last+tag@sub.example.co.uk".isValidEmail)
    }

    func testRejectsIncompleteAddresses() {
        XCTAssertFalse("".isValidEmail)
        XCTAssertFalse("david".isValidEmail)
        XCTAssertFalse("david@".isValidEmail)
        XCTAssertFalse("david@drssed".isValidEmail)
        XCTAssertFalse("@drssed.app".isValidEmail)
    }
}

final class ClothingCategoryDecodingTests: XCTestCase {

    private struct Payload: Decodable {
        let category: ClothingCategories
        let sub_category: ClothingSubCategories
    }

    private func decode(category: String, subCategory: String) throws -> Payload {
        let json = #"{"category":"\#(category)","sub_category":"\#(subCategory)"}"#

        return try JSONDecoder().decode(Payload.self, from: Data(json.utf8))
    }

    func testKnownValuesDecode() throws {
        let payload = try decode(category: "TOP", subCategory: "HOODIE")

        XCTAssertEqual(payload.category, .TOP)
        XCTAssertEqual(payload.sub_category, .HOODIE)
    }

    func testLowercasedValuesDecode() throws {
        let payload = try decode(category: "top", subCategory: "hoodie")

        XCTAssertEqual(payload.category, .TOP)
        XCTAssertEqual(payload.sub_category, .HOODIE)
    }

    func testUnknownValuesFallBackInsteadOfFailing() throws {
        let payload = try decode(category: "FOOTWEAR", subCategory: "SNEAKER")

        XCTAssertEqual(payload.category, .UNKNOWN)
        XCTAssertEqual(payload.sub_category, .UNKNOWN)
    }
}

final class WearCalendarDayTests: XCTestCase {

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    private func august2026() throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 3)))
    }

    func testMonthIsPaddedToFullWeeks() throws {
        let days = WearCalendarDay.month(for: try august2026(), wears: [], calendar: calendar)

        XCTAssertFalse(days.isEmpty)
        XCTAssertEqual(days.count % 7, 0)
    }

    func testMonthCoversEveryDayExactlyOnce() throws {
        let days = WearCalendarDay.month(for: try august2026(), wears: [], calendar: calendar)
        let numbers = days.compactMap { $0.date }.map { calendar.component(.day, from: $0) }

        XCTAssertEqual(numbers, Array(1...31))
    }

    func testPaddingCellsCarryNoDate() throws {
        let days = WearCalendarDay.month(for: try august2026(), wears: [], calendar: calendar)
        let padding = days.filter { $0.date == nil }

        XCTAssertEqual(padding.count, days.count - 31)
        XCTAssertTrue(padding.allSatisfy { $0.wears.isEmpty })
    }

    func testTodayIsMarkedOnceInTheCurrentMonth() {
        let days = WearCalendarDay.month(for: Date(), wears: [], calendar: .current)

        XCTAssertEqual(days.filter(\.isToday).count, 1)
    }

    func testOtherMonthsHaveNoToday() throws {
        let lastYear = try XCTUnwrap(calendar.date(byAdding: .year, value: -1, to: Date()))
        let days = WearCalendarDay.month(for: lastYear, wears: [], calendar: calendar)

        XCTAssertTrue(days.allSatisfy { !$0.isToday })
    }
}

final class RateLimitRetryTests: XCTestCase {
    private func response(retryAfter: String?) -> HTTPURLResponse? {
        var headers: [String: String] = [:]
        if let retryAfter { headers["Retry-After"] = retryAfter }

        return HTTPURLResponse(
            url: URL(string: "https://api.drssed.app/users/me")!,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
    }

    func testWaitsOutAShortLimit() {
        XCTAssertEqual(APIClient.retryDelay(from: response(retryAfter: "2")), 2)
        XCTAssertEqual(APIClient.retryDelay(from: response(retryAfter: " 5 ")), 5)
    }

    func testSurfacesALongLimitInsteadOfBlocking() {
        XCTAssertNil(APIClient.retryDelay(from: response(retryAfter: "61")))
        XCTAssertNil(APIClient.retryDelay(from: response(retryAfter: "3600")))
    }

    func testIgnoresMissingOrUnusableHeaders() {
        XCTAssertNil(APIClient.retryDelay(from: response(retryAfter: nil)))
        XCTAssertNil(APIClient.retryDelay(from: response(retryAfter: "0")))
        XCTAssertNil(APIClient.retryDelay(from: response(retryAfter: "-3")))
        XCTAssertNil(APIClient.retryDelay(from: response(retryAfter: "Wed, 21 Oct 2026 07:28:00 GMT")))
        XCTAssertNil(APIClient.retryDelay(from: nil))
    }
}
