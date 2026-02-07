//
//  Segment.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftData
import Foundation
internal import CoreGraphics

@Model
class Segment {
    @Attribute(.unique) var id: UUID
    /// Direct reference to image file
    var imagePath: String  

    /// Explicit ordering for playback sequence
    var orderIndex: Int  
    
    var boundingBoxX: Double
    var boundingBoxY: Double
    var boundingBoxWidth: Double
    var boundingBoxHeight: Double

    var markers: [NavigationMarker]
    
    /// An optional user-provided label for this segment (e.g., "Chorus", "Verse").
    var label: String?
    
    /// Serialized PKDrawing
    var drawingData: Data?  
    
    /// Bounding box in normalized 0-1 coordinates relative to source image
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
        self.markers = []
    }
}

