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
