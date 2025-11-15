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
        
        // Load test image from Assets and save to Documents (proper production flow)
        if let testImage = UIImage(named: "TestSheetMusic1") {
            if let filename = try? imageStore.save(testImage, documentName: doc.name, index: 0) {
                doc.imagePaths = [filename]
            }
        }
        
        // Add sample frames with some bounding boxes
        // Full-width frames, 1/10 page height each, stacked vertically like sheet music lines
        if !doc.imagePaths.isEmpty {
            let frame1 = Frame(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.1)
            )
            
            let frame2 = Frame(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.15, width: 1.0, height: 0.1)
            )
            
            let frame3 = Frame(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.30, width: 1.0, height: 0.1)
            )
            
            let frame4 = Frame(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.45, width: 1.0, height: 0.1)
            )
            
            let frame5 = Frame(
                imagePath: doc.imagePaths[0],
                boundingBox: CGRect(x: 0.0, y: 0.60, width: 1.0, height: 0.1)
            )
            
            doc.frames = [frame1, frame2, frame3, frame4, frame5]
        }
        
        context.insert(doc)
        try? context.save()
        
        return doc
    }
    
    static func createPreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: SheetMusicDocument.self, Frame.self,
            configurations: config
        )
        return container
    }
}
#endif

