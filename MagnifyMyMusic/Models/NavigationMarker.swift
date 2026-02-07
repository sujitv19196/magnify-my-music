//
//  NavigationMarker.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/7/26.
//  Adapted from MusicXML specification: https://www.w3.org/2021/06/musicxml40/

import SwiftData
import Foundation

@Model
class NavigationMarker {
    @Attribute(.unique) var id: UUID

    var type: NavigationMarkerType

    /// 0.0-1.0 normalized position within the segment's bounding box
    var xPosition: Double

    init(type: NavigationMarkerType, xPosition: Double) {
        self.id = UUID()
        self.type = type
        self.xPosition = xPosition
    }
}

enum NavigationMarkerType: Codable {
    // MARK: - Barline-level markers
    
    /// Marks the start of a repeated section in the score (||:).
    case repeatForward
    
    /// Marks the end of a repeated section in the score (:||).
    /// - times: How many times to repeat (default 1)
    case repeatBackward(times: Int = 1)
    
    // MARK: - Volta endings
    
    /// Start of a volta bracket (e.g., "1.", "2.", etc.), marking the beginning of a repeated ending section.
    /// - numbers: Which endings this applies to, e.g. [1], [2], [1, 2]
    case endingStart(numbers: [Int])
    
    /// End of volta with a downward hook (typically used for the first ending).
    /// - numbers: Which endings this applies to
    case endingStop(numbers: [Int])
    
    /// End of volta without a hook (typically used for the last ending).
    /// -  numbers: Which endings this applies to
    case endingDiscontinue(numbers: [Int])
    
    // MARK: - Jump targets (semantic destinations)
    
    /// Segno — destination for D.S. (Dal Segno) jumps in the score.
    /// - label: Token name for matching (e.g. "segno1")
    case segno(label: String? = nil)
    
    /// Coda — destination for "To Coda" jumps in the score.
    /// - label: Token name for matching (e.g. "coda1")
    case coda(label: String? = nil)
    
    // MARK: - Jump commands (semantic actions)
    
    /// D.C. — jump to beginning of the piece
    case dacapo
    
    /// D.S. — jump back to the most recent segno marker
    /// - label: Token name for matching segno target (e.g. "segno1")
    case dalsegno(label: String? = nil)
    
    /// To Coda — jump forward to the coda section
    /// - label: Token name for matching coda target (e.g. "coda1")
    case tocoda(label: String? = nil)
    
    /// Fine — end of the piece after D.C./D.S.
    case fine
    
    // MARK: - V2 Cases (Deferred)
    
    // **V2:** Add case variants for:
    // - timeOnly modifier (which pass triggers a jump) — rare in printed music
    // - afterJump (whether repeats honor after D.S./D.C.) — pick sensible default for now: skip repeats after jump
    // - forwardRepeatImplied — very rare edge case (minuet/trio forms)
}
