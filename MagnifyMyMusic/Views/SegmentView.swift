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
    let tool: PKTool
    var drawingPolicy: PKCanvasViewDrawingPolicy = .pencilOnly

    @State private var canvas = PKCanvasView()
    @State private var drawing = PKDrawing()

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .allowsHitTesting(false)
            .overlay {
                PencilKitCanvas(
                    canvasView: $canvas,
                    drawing: $drawing,
                    tool: tool,
                    drawingPolicy: drawingPolicy,
                    onSave: saveDrawing
                )
            }
            .task {
                loadDrawing()
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
