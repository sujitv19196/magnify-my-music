//
//  NavigationMarker.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/7/26.
//  

import Foundation

@Observable
class NavigationMarker: Identifiable, Codable {
    var id: UUID
    
    /// The type of navigation marker (repeat, volta, segno, coda, etc.)
    var type: NavigationMarkerType

    /// 0.0-1.0 normalized position within the segment's bounding box
    var xPosition: Double

    init(type: NavigationMarkerType, xPosition: Double) {
        self.id = UUID()
        self.type = type
        self.xPosition = xPosition
    }
    
    // MARK: - Codable 
    
    enum CodingKeys: String, CodingKey {
        case id, type, xPosition
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(NavigationMarkerType.self, forKey: .type)
        xPosition = try container.decode(Double.self, forKey: .xPosition)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(xPosition, forKey: .xPosition)
    }
}

enum NavigationMarkerType: Codable, Sendable {
    // MARK: - Repeats (simple, no volta)
    
    /// Marks the start of a repeated section in the score (||:).
    case repeatForward
    
    /// Marks the end of a simple repeated section in the score (:||).
    /// Only used for repeats **without** volta endings.
    /// - Parameter times: How many times to jump back (1 = play twice total).
    case repeatBackward(times: Int = 1)
    
    // MARK: - Volta endings
    
    /// Start of a volta bracket (e.g., "1.", "2.", "1,2").
    /// - Parameter numbers: Which repeat passes this ending applies to, e.g. [1], [2], [1, 2].
    case volta(numbers: [Int])
    
    /// Marks the end of the final volta bracket in a section.
    case finalVoltaEnd
    
    // MARK: - Jump targets (semantic destinations)
    
    /// Segno — destination for D.S. (Dal Segno) jumps in the score.
    /// - Parameter label: Token name for matching (e.g. "segno1").
    case segno(label: String? = nil)
    
    /// Coda — destination for "To Coda" jumps in the score.
    /// - Parameter label: Token name for matching (e.g. "coda1").
    case coda(label: String? = nil)
    
    // MARK: - Jump commands (semantic actions)
    
    /// D.C. — jump to beginning of the piece.
    case dacapo
    
    /// D.S. — jump back to the most recent segno marker.
    /// - Parameter label: Token name for matching segno target (e.g. "segno1").
    case dalsegno(label: String? = nil)
    
    /// To Coda — jump forward to the coda section.
    /// - Parameter label: Token name for matching coda target (e.g. "coda1").
    case tocoda(label: String? = nil)
    
    /// Fine — end of the piece after D.C./D.S.
    case fine
    
    // MARK: - V2 Cases (Deferred)
    
    // **V2:** Add case variants for:
    // - timeOnly modifier (which pass triggers a jump) — rare in printed music
    // - afterJump (whether repeats honor after D.S./D.C.) — pick sensible default for now: skip repeats after jump
    // - forwardRepeatImplied — very rare edge case (minuet/trio forms)
}
