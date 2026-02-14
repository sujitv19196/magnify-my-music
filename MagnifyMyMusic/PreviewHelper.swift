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
    /// Fixed UUID so preview data always overwrites the same bundle on disk.
    private static let sampleDocId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    static func createSampleDocument() -> SheetMusicDocument {
        let doc = SheetMusicDocument(name: "Moanin")
        doc.id = sampleDocId
        
        // Placeholder filenames — actual images are created by createPreviewStore()
        doc.imagePaths = ["preview_page_0.jpg", "preview_page_1.jpg"]
        
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
    
    /// Creates a DocumentStore with sample data saved to disk (including placeholder images).
    /// Uses a fixed document UUID so previews always overwrite the same bundle.
    static func createPreviewStore() -> DocumentStore {
        let store = DocumentStore()
        let doc = createSampleDocument()
        
        // Save document to disk so loadDocument(id:) works
        try? store.save(doc)
        
        // Write the asset catalog images into the bundle so loadImage() works
        let assetNames = ["TestSheetMusic1", "TestSheetMusic2"]
        let imagesDir = store.bundleURL(for: doc.id).appendingPathComponent("images")
        for (filename, assetName) in zip(doc.imagePaths, assetNames) {
            let fileURL = imagesDir.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: fileURL.path),
               let image = UIImage(named: assetName) {
                try? image.jpegData(compressionQuality: 0.9)?.write(to: fileURL)
            }
        }
        
        return store
    }
}
#endif
