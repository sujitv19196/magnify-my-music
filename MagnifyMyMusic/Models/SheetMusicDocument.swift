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
    
    var imagePaths: [String] {  // Filenames: "DocumentName_0.jpg", "DocumentName_1.jpg"
        didSet { modifiedAt = Date() }
    }
    
    var frames: [Frame] {      // Array order IS the frame sequence
        didSet { modifiedAt = Date() }
    }
    
    var repeats: [Repeat] {    // Repeat structures for navigation
        didSet { modifiedAt = Date() }
    }
    
    var createdAt: Date
    var modifiedAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.imagePaths = []
        self.frames = []
        self.repeats = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

