//
//  Date+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation

extension Date {
    static let iso8601Formatter: DateFormatter = {
//        let formatter = ISO8601DateFormatter()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    var iso8601: String {
        return Date.iso8601Formatter.string(from: self)
    }
}
