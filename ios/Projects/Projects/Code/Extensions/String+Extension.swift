//
//  String+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/14/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

extension String {
    var length: Int {
        return self.characters.count
    }
    
    subscript (i: Int) -> String {
        return self[Range(i ..< i + 1)]
    }
    
    func substring(from: Int) -> String {
        return self[Range(min(from, length) ..< length)]
    }
    
    func substring(to: Int) -> String {
        return self[Range(0 ..< max(0, to))]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[Range(start ..< end)])
    }
    
    static func fileSizeToString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = [
            NSLocalizedString("bytes", comment: "Data units"),
            NSLocalizedString("Kb", comment: "Data units"),
            NSLocalizedString("Mb", comment: "Data units"),
            NSLocalizedString("Gb", comment: "Data units"),
            NSLocalizedString("Tb", comment: "Data units"),
            NSLocalizedString("Pb", comment: "Data units"),
            NSLocalizedString("Eb", comment: "Data units"),
            NSLocalizedString("Zb", comment: "Data units"),
            NSLocalizedString("Yb", comment: "Data units")
        ]
        
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
    
    var dateFromISO8601: Date? {
        return Date.iso8601Formatter.date(from: self)
    }
    
    func fileName() -> String {
        return ((self as NSString).deletingPathExtension as NSString).lastPathComponent
    }
    
    func fileExtension() -> String {
        return (self as NSString).pathExtension
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Inner comparison utility to handle same versions with different length. (Ex: "1.0.0" & "1.0")
    private func compare(toVersion targetVersion: String) -> ComparisonResult {
        
        let versionDelimiter = "."
        var result: ComparisonResult = .orderedSame
        var versionComponents = components(separatedBy: versionDelimiter)
        var targetComponents = targetVersion.components(separatedBy: versionDelimiter)
        let spareCount = versionComponents.count - targetComponents.count
        
        if spareCount == 0 {
            result = compare(targetVersion, options: .numeric)
        } else {
            let spareZeros = repeatElement("0", count: abs(spareCount))
            if spareCount > 0 {
                targetComponents.append(contentsOf: spareZeros)
            } else {
                versionComponents.append(contentsOf: spareZeros)
            }
            result = versionComponents.joined(separator: versionDelimiter)
                .compare(targetComponents.joined(separator: versionDelimiter), options: .numeric)
        }
        return result
    }
    
    public func isVersion(equalTo targetVersion: String) -> Bool { return compare(toVersion: targetVersion) == .orderedSame }
    public func isVersion(greaterThan targetVersion: String) -> Bool { return compare(toVersion: targetVersion) == .orderedDescending }
    public func isVersion(greaterThanOrEqualTo targetVersion: String) -> Bool { return compare(toVersion: targetVersion) != .orderedAscending }
    public func isVersion(lessThan targetVersion: String) -> Bool { return compare(toVersion: targetVersion) == .orderedAscending }
    public func isVersion(lessThanOrEqualTo targetVersion: String) -> Bool { return compare(toVersion: targetVersion) != .orderedDescending }
}
