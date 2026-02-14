//
//  PreviewHelper.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

#if DEBUG
@MainActor
struct PreviewHelper {
    static func createSampleDocument() -> SheetMusicDocument {
        let doc = SheetMusicDocument(name: "Moanin")
        
        // In previews we don't have real images on disk, so use placeholder paths.
        // Views that try to load these will gracefully fail.
        doc.imagePaths = ["page_0.jpg", "page_1.jpg"]
        
        // Add sample segments aligned with actual staff systems
        let segment1 = Segment(
            imagePath: doc.imagePaths[0],
            boundingBox: CGRect(x: 0.0, y: 0.14, width: 1.0, height: 0.08)
        )
        
        let segment2 = Segment(
            imagePath: doc.imagePaths[0],
            boundingBox: CGRect(x: 0.0, y: 0.22, width: 1.0, height: 0.08)
        )
        
        let segment3 = Segment(
            imagePath: doc.imagePaths[0],
            boundingBox: CGRect(x: 0.0, y: 0.30, width: 1.0, height: 0.08)
        )
        
        let segment4 = Segment(
            imagePath: doc.imagePaths[0],
            boundingBox: CGRect(x: 0.0, y: 0.37, width: 1.0, height: 0.08)
        )
        
        let segment5 = Segment(
            imagePath: doc.imagePaths[0],
            boundingBox: CGRect(x: 0.0, y: 0.45, width: 1.0, height: 0.08)
        )
        
        // -- Add navigation markers --

        // Simple repeat: segment2 through segment3 plays twice
        segment2.markers = [
            NavigationMarker(type: .repeatForward, xPosition: 0.0)
        ]
        segment3.markers = [
            NavigationMarker(type: .repeatBackward(), xPosition: 1.0)
        ]

        // Volta endings on segment4 and segment5:
        // Pass 1 → play segment4, Pass 2 → play segment5
        segment4.markers = [
            NavigationMarker(type: .repeatForward, xPosition: 0.0),
            NavigationMarker(type: .volta(numbers: [1]), xPosition: 0.3)
        ]
        segment5.markers = [
            NavigationMarker(type: .volta(numbers: [2]), xPosition: 0.0),
            NavigationMarker(type: .finalVoltaEnd, xPosition: 1.0)
        ]

        doc.segments = [segment1, segment2, segment3, segment4, segment5]
        
        return doc
    }
    
    static func createPreviewStore() -> DocumentStore {
        // Returns a store that scans the default directory.
        // For in-memory previews, the directory will be empty — that's fine.
        return DocumentStore()
    }
}
#endif
