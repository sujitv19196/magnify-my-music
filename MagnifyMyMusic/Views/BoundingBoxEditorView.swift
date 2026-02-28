//
//  BoundingBoxEditorView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

struct BoundingBoxEditorView: View {
    @Bindable var document: SheetMusicDocument
    let imagePath: String
    
    @Environment(DocumentStore.self) var store
    @State private var currentBox: CGRect?
    @State private var dragStart: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            if let image = try? store.loadImage(imagePath, from: document.id) {
                let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: image.size)
                
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    ForEach(segmentsForCurrentImage) { segment in
                        let boxWidth = segment.boundingBoxWidth * imageFrame.width
                        let boxHeight = segment.boundingBoxHeight * imageFrame.height
                        let boxX = imageFrame.minX + segment.boundingBoxX * imageFrame.width
                        let boxY = imageFrame.minY + segment.boundingBoxY * imageFrame.height
                        
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: boxWidth, height: boxHeight)
                            .overlay(alignment: .trailing) {
                                Button {
                                    deleteSegment(segment)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.red)
                                        .background(Circle().fill(Color.white))
                                }
                                .offset(x: 40)
                            }
                            .position(x: boxX + boxWidth / 2, y: boxY + boxHeight / 2)
                            .id(segment.id)
                    }
                    if let box = currentBox {
                        Rectangle()
                            .stroke(Color.green, lineWidth: 3)
                            .frame(width: box.width, height: box.height)
                            .position(x: box.midX, y: box.midY)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Clamp coordinates to image bounds
                            let clampedStart = clampToImage(point: dragStart, imageFrame: imageFrame)
                            let clampedCurrent = clampToImage(point: value.location, imageFrame: imageFrame)
                            
                            let width = abs(clampedCurrent.x - clampedStart.x)
                            let height = abs(clampedCurrent.y - clampedStart.y)
                            let x = min(clampedStart.x, clampedCurrent.x)
                            let y = min(clampedStart.y, clampedCurrent.y)
                            
                            currentBox = CGRect(x: x, y: y, width: width, height: height)
                        }
                        .onEnded { value in
                            if let box = currentBox, box.width > 20, box.height > 20 {
                                // Normalize relative to image frame, not container
                                let normalizedBox = CGRect(
                                    x: (box.origin.x - imageFrame.minX) / imageFrame.width,
                                    y: (box.origin.y - imageFrame.minY) / imageFrame.height,
                                    width: box.width / imageFrame.width,
                                    height: box.height / imageFrame.height
                                )
                                
                                let segment = Segment(
                                    imagePath: imagePath,
                                    boundingBox: normalizedBox
                                )
                                
                                document.segments.append(segment)
                            }
                            
                            currentBox = nil
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if currentBox == nil {
                                dragStart = value.startLocation
                            }
                        }
                )
            }
        }
        .onDisappear {
            try? store.save(document)
        }
    }
    
    private func clampToImage(point: CGPoint, imageFrame: CGRect) -> CGPoint {
        return CGPoint(
            x: min(max(point.x, imageFrame.minX), imageFrame.maxX),
            y: min(max(point.y, imageFrame.minY), imageFrame.maxY)
        )
    }
    
    private var segmentsForCurrentImage: [Segment] {
        document.segments.filter { $0.imagePath == imagePath }
    }
    
    private func deleteSegment(_ segment: Segment) {
        if let index = document.segments.firstIndex(where: { $0.id == segment.id }) {
            document.segments.remove(at: index)
        }
    }
}
