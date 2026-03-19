//
//  DateParser.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/19.
//

import Foundation

/// Utility class for parsing date strings in various formats
enum DateParser {

    /// Supported date formats
    private static let dateFormats: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",      // ISO8601 with milliseconds
            "yyyy-MM-dd'T'HH:mm:ssZ",          // ISO8601
            "yyyy-MM-dd'T'HH:mm:ss",           // ISO8601 without timezone
            "yyyy-MM-dd HH:mm:ss",             // Common SQL format
            "yyyy-MM-dd HH:mm",                // SQL format without seconds
            "yyyy/MM/dd HH:mm:ss",             // Alternative format
            "yyyy/MM/dd HH:mm",                // Alternative format without seconds
            "yyyy-MM-dd",                      // Date only
        ]

        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }
    }()

    /// ISO8601 formatter with options
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FormatterNoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parse a date string into a Date object
    /// - Parameter dateString: The date string to parse
    /// - Returns: A Date object if parsing succeeds, nil otherwise
    static func parse(_ dateString: String) -> Date? {
        guard !dateString.isEmpty else { return nil }

        // Try ISO8601 formatters first (more efficient)
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        if let date = iso8601FormatterNoFractional.date(from: dateString) {
            return date
        }

        // Try other formats
        for formatter in dateFormats {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        // Log warning if parsing fails
        Logger.community.warning("Failed to parse date string: \(dateString)")
        return nil
    }

    /// Format a date as a relative time string (e.g., "2 hours ago")
    /// - Parameter date: The date to format
    /// - Returns: A relative time string
    static func relativeTime(from date: Date?) -> String {
        guard let date = date else { return "" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
