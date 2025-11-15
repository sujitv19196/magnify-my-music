//
//  Frame.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftData
import Foundation
internal import CoreGraphics

@Model
class Frame {
    @Attribute(.unique) var id: UUID
    var imagePath: String  // Direct reference to image file
    var orderIndex: Int  // Explicit ordering for playback sequence
    
    // CGRect stored as separate properties (SwiftData requirement)
    var boundingBoxX: Double
    var boundingBoxY: Double
    var boundingBoxWidth: Double
    var boundingBoxHeight: Double
    
    var label: String?  // Optional user label
    var drawingData: Data?  // Serialized PKDrawing
    
    // Computed property for convenience
    var boundingBox: CGRect {
        get { 
            CGRect(x: boundingBoxX, y: boundingBoxY, 
                   width: boundingBoxWidth, height: boundingBoxHeight) 
        }
        set {
            boundingBoxX = newValue.origin.x
            boundingBoxY = newValue.origin.y
            boundingBoxWidth = newValue.width
            boundingBoxHeight = newValue.height
        }
    }
    
    init(imagePath: String, boundingBox: CGRect, orderIndex: Int) {
        self.id = UUID()
        self.imagePath = imagePath
        self.orderIndex = orderIndex
        self.boundingBoxX = boundingBox.origin.x
        self.boundingBoxY = boundingBox.origin.y
        self.boundingBoxWidth = boundingBox.width
        self.boundingBoxHeight = boundingBox.height
        self.drawingData = nil
    }
}

