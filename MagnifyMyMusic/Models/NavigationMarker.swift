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

    /// Token name for matching segno/coda pairs (e.g. "segno1", "coda1")
    var label: String?

    /// For repeatBackward: how many times to repeat (default 2)
    var times: Int?

    /// For volta endings: e.g. [1], [2], [1, 2]
    var endingNumbers: [Int]?

    // MARK: - Deferred to V2
    /// **V2:** Which pass triggers a jump (time-only modifier). Rare in printed music.
    var timeOnlyPass: Int?

    /// **V2:** Whether repeats are honored after D.S./D.C. Default for now: skip repeats after jump. Ambiguous in sheet music notation.
    var afterJumpHonorRepeats: Bool?

    /// **V2:** Forward repeat implied (e.g. minuet/trio forms). Very rare edge case.
    var forwardRepeatImplied: Bool?

    init(type: NavigationMarkerType, xPosition: Double, label: String? = nil,
         times: Int? = nil, endingNumbers: [Int]? = nil,
         timeOnlyPass: Int? = nil, afterJumpHonorRepeats: Bool? = nil, forwardRepeatImplied: Bool? = nil) {
        self.id = UUID()
        self.type = type
        self.xPosition = xPosition
        self.label = label
        self.times = times
        self.endingNumbers = endingNumbers
        self.timeOnlyPass = timeOnlyPass
        self.afterJumpHonorRepeats = afterJumpHonorRepeats
        self.forwardRepeatImplied = forwardRepeatImplied
    }
}

enum NavigationMarkerType: String, Codable {
    // Barline-level markers
    /// Marks the start of a repeated section in the score (||:).
    case repeatForward       

    /// Marks the end of a repeated section in the score (:||).
    case repeatBackward      

    // Volta endings //
    /// Start of a volta bracket (e.g., "1.", "2.", etc.), marking the beginning of a repeated ending section.
    case endingStart

    /// End of volta with a downward hook (typically used for the first ending).
    case endingStop

    /// End of volta without a hook (typically used for the last ending).
    case endingDiscontinue

    // Jump targets (semantic destinations) //
    /// Segno — destination for D.S. (Dal Segno) jumps in the score.
    case segno

    /// Coda — destination for "To Coda" jumps in the score.
    case coda

    // Jump commands (semantic actions) //
    /// D.C. — jump to beginning of the piece
    case dacapo              

    /// D.S. — jump back to the most recent segno marker
    case dalsegno            

    /// To Coda — jump forward to the coda section
    case tocoda              

    /// Fine — end of the piece after D.C./D.S.
    case fine                
}