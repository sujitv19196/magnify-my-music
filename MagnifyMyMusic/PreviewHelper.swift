//
//  PreviewHelper.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import SwiftData

#if DEBUG
@MainActor
struct PreviewHelper {
    static func createSampleDocument(in container: ModelContainer) -> SheetMusicDocument {
        let context = container.mainContext
        let imageStore = ImageStore()
        
        // Create a sample document
        let doc = SheetMusicDocument(name: "Moanin")
        
        // Load test images from Assets and save to Documents (proper production flow)
        var imagePaths: [String] = []
        
        if let testImage1 = UIImage(named: "TestSheetMusic1") {
            if let filename = try? imageStore.save(testImage1, documentName: doc.name, index: 0) {
                imagePaths.append(filename)
            }
        }
        
        if let testImage2 = UIImage(named: "TestSheetMusic2") {
            if let filename = try? imageStore.save(testImage2, documentName: doc.name, index: 1) {
                imagePaths.append(filename)
            }
        }
        
        doc.imagePaths = imagePaths
        
        // Add sample segments aligned with actual staff systems in test.svg
        // SVG dimensions: 2976.38 × 4209.45, staff systems at specific Y positions
        // Including space above/below each staff for dynamics and articulations
        if !doc.imagePaths.isEmpty {
            let segment1 = Segment(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.14, width: 1.0, height: 0.08),  // Staff 1 (14-22%)
                orderIndex: 0
            )
            
            let segment2 = Segment(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.22, width: 1.0, height: 0.08),  // Staff 2 (22-30%)
                orderIndex: 1
            )
            
            let segment3 = Segment(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.30, width: 1.0, height: 0.08),  // Staff 3 (30-38%)
                orderIndex: 2
            )
            
            let segment4 = Segment(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.37, width: 1.0, height: 0.08),  // Staff 4 (37-45%)
                orderIndex: 3
            )
            
            let segment5 = Segment(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.45, width: 1.0, height: 0.08),  // Staff 5 (45-53%)
                orderIndex: 4
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
        }
        
        context.insert(doc)
        try? context.save()
        
        return doc
    }
    
    static func createPreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: SheetMusicDocument.self, Segment.self, NavigationMarker.self,
            configurations: config
        )
        return container
    }
}
#endif

