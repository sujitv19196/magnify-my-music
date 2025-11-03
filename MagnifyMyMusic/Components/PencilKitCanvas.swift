//
//  PencilKitCanvas.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit

struct PencilKitCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawing: PKDrawing
    let tool: PKInkingTool
    let onSave: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawing = drawing
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .pencilOnly
        canvasView.tool = tool
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
        uiView.tool = tool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, onSave: onSave)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let onSave: () -> Void
        
        init(drawing: Binding<PKDrawing>, onSave: @escaping () -> Void) {
            self._drawing = drawing
            self.onSave = onSave
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async {
                self.drawing = canvasView.drawing
                self.onSave()
            }
        }
    }
}

