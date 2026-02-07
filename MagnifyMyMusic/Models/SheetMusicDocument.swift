//
//  SheetMusicDocument.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftData
import Foundation

@Model
class SheetMusicDocument {
    @Attribute(.unique) var id: UUID
    
    var name: String {
        didSet { modifiedAt = Date() }
    }
    
    var imagePaths: [String] {
        didSet { modifiedAt = Date() }
    }
    
    var segments: [Segment] {
        didSet { modifiedAt = Date() }
    }
    
    var createdAt: Date
    var modifiedAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.imagePaths = []
        self.segments = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

