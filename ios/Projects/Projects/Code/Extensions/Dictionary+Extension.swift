//
//  Dictionary+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation

extension Dictionary {
    func stringAsHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            if let strKey = key as? String,
               let strValue = value as? String,
               let encodeKey = strKey.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
               let encodeValue = strValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                return "\(encodeKey)=\(encodeValue)"
            }
            return ""
        }
        
        return parameterArray.joined(separator: "&")
    }
    
    // MARK: - Operators
    
    /// Merge the keys/values of two dictionaries.
    ///
    /// - Parameters:
    ///   - lhs: dictionary
    ///   - rhs: dictionary
    /// - Returns: An dictionary with keys and values from both.
    public static func +(lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        var result = lhs
        rhs.forEach{ result[$0] = $1 }
        return result
    }
    
    /// Append the keys and values from the second dictionary into the first one.
    ///
    /// - Parameters:
    ///   - lhs: dictionary
    ///   - rhs: dictionary
    public static func +=(lhs: inout [Key: Value], rhs: [Key: Value]) {
        rhs.forEach({ lhs[$0] = $1})
    }

    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
}
