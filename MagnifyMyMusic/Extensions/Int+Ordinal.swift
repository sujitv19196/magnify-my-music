//
//  Int+Ordinal.swift
//  MagnifyMyMusic
//

import Foundation

extension Int {
    /// Returns the ordinal form of the integer (e.g. 1 → "1st", 2 → "2nd", 3 → "3rd", 4 → "4th").
    var ordinalString: String {
        let n = Swift.abs(self)
        let suffix: String
        if (11...13).contains(n % 100) {
            suffix = "th"
        } else {
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
}
