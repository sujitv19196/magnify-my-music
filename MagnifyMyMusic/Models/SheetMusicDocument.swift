//
//  SheetMusicDocument.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import Foundation

private let currentSchemaVersion = 1

@Observable
class SheetMusicDocument: Identifiable, Codable {
    var version: Int
    
    var id: UUID
    var name: String
    var imagePaths: [String]
    var segments: [Segment]
    var createdAt: Date
    var modifiedAt: Date
    
    init(name: String) {
        self.version = currentSchemaVersion
        self.id = UUID()
        self.name = name
        self.imagePaths = []
        self.segments = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Codable 

    enum CodingKeys: String, CodingKey {
        case version, id, name, imagePaths, segments, createdAt, modifiedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imagePaths = try container.decode([String].self, forKey: .imagePaths)
        segments = try container.decode([Segment].self, forKey: .segments)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(imagePaths, forKey: .imagePaths)
        try container.encode(segments, forKey: .segments)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
    }
}

extension SheetMusicDocument {
    /// Infers the page number for a segment from its position in `imagePaths`.
    /// Returns nil if the segment's imagePath is not found (orphaned segment).
    func pageNumber(for segment: Segment) -> Int? {
        imagePaths.firstIndex(of: segment.imagePath)
    }

    /// Segments in playback order, excluding any with unresolved imagePaths.
    /// Sorted by: page number, then top-to-bottom (Y), then left-to-right (X).
    var sortedSegments: [Segment] {
        segments
            .filter { pageNumber(for: $0) != nil }
            .sorted {
                let p0 = pageNumber(for: $0)!
                let p1 = pageNumber(for: $1)!
                if p0 != p1 { return p0 < p1 }
                if $0.boundingBoxY != $1.boundingBoxY { return $0.boundingBoxY < $1.boundingBoxY }
                return $0.boundingBoxX < $1.boundingBoxX
            }
    }

    /// Segments whose imagePath doesn't match any entry in imagePaths.
    var orphanedSegments: [Segment] {
        segments.filter { pageNumber(for: $0) == nil }
    }
}
