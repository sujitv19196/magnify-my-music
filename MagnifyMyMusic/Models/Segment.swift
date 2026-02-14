//
//  Segment.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import Foundation
internal import CoreGraphics

@Observable
class Segment: Identifiable, Codable {
    var id: UUID
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
    
    // MARK: - Codable 
    
    enum CodingKeys: String, CodingKey {
        case id, imagePath, orderIndex
        case boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight
        case markers, label, drawingData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        imagePath = try container.decode(String.self, forKey: .imagePath)
        orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        boundingBoxX = try container.decode(Double.self, forKey: .boundingBoxX)
        boundingBoxY = try container.decode(Double.self, forKey: .boundingBoxY)
        boundingBoxWidth = try container.decode(Double.self, forKey: .boundingBoxWidth)
        boundingBoxHeight = try container.decode(Double.self, forKey: .boundingBoxHeight)
        markers = try container.decode([NavigationMarker].self, forKey: .markers)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        drawingData = try container.decodeIfPresent(Data.self, forKey: .drawingData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(boundingBoxX, forKey: .boundingBoxX)
        try container.encode(boundingBoxY, forKey: .boundingBoxY)
        try container.encode(boundingBoxWidth, forKey: .boundingBoxWidth)
        try container.encode(boundingBoxHeight, forKey: .boundingBoxHeight)
        try container.encode(markers, forKey: .markers)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(drawingData, forKey: .drawingData)
    }
}
