//
//  SegmentView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit

struct SegmentView: View {
    @Bindable var segment: Segment
    let image: UIImage
    let tool: PKInkingTool
    
    @State private var canvas = PKCanvasView()
    @State private var drawing = PKDrawing()
    
    var body: some View {
        if let croppedImage = image.cropped(to: segment.boundingBox) {
            let aspectRatio = croppedImage.size.width / croppedImage.size.height
            
            ZStack {
                    Image(uiImage: croppedImage)
                        .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                        .allowsHitTesting(false)
                
                GeometryReader { geometry in
                PencilKitCanvas(
                    canvasView: $canvas,
                    drawing: $drawing,
                    tool: tool,
                    onSave: saveDrawing
                )
            }
        }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .task {
            loadDrawing()
            }
        } else {
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 200, height: 200)
                .overlay(Text("Failed to load segment"))
        }
    }
    
    private func loadDrawing() {
        if let data = segment.drawingData,
           let savedDrawing = try? PKDrawing(data: data) {
            drawing = savedDrawing
            canvas.drawing = savedDrawing
        }
    }
    
    private func saveDrawing() {
        segment.drawingData = drawing.dataRepresentation()
    }
}

