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
    var containerHeight: CGFloat = 0
    var startX: Double = 0.0
    var endX: Double = 1.0

    @State private var canvas = PKCanvasView()
    @State private var drawing = PKDrawing()

    private var cropRect: CGRect {
        let box = segment.boundingBox
        return CGRect(
            x: box.minX + startX * box.width,
            y: box.minY,
            width: (endX - startX) * box.width,
            height: box.height
        )
    }

    var body: some View {
        if let croppedImage = image.cropped(to: cropRect) {
            let aspectRatio = croppedImage.size.width / croppedImage.size.height

            Image(uiImage: croppedImage)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fit)
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
