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
                let imageSegment = calculateImageSegment(containerSize: geometry.size, imageSize: image.size)
                
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    let maxOrderIndex = document.segments.map { $0.orderIndex }.max() ?? -1
                    
                    ForEach(segmentsForCurrentImage) { segment in
                        let boxWidth = segment.boundingBoxWidth * imageSegment.width
                        let boxHeight = segment.boundingBoxHeight * imageSegment.height
                        let boxX = imageSegment.minX + segment.boundingBoxX * imageSegment.width
                        let boxY = imageSegment.minY + segment.boundingBoxY * imageSegment.height
                        let isLastSegment = segment.orderIndex == maxOrderIndex
                        
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: boxWidth, height: boxHeight)
                            .overlay(alignment: .leading) {
                                // Segment number - center left of box
                                Text("\(segment.orderIndex + 1)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                                    .offset(x: -40)
                            }
                            .overlay(alignment: .trailing) {
                                // Delete button - center right of box (only for last segment)
                                if isLastSegment {
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
                            }
                            .position(x: boxX + boxWidth / 2, y: boxY + boxHeight / 2)
                            .id("\(segment.id)-\(segment.orderIndex)")
                    }
                    .drawingGroup()  // Composite segments into single GPU layer for better performance
                    
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
                            let clampedStart = clampToImage(point: dragStart, imageSegment: imageSegment)
                            let clampedCurrent = clampToImage(point: value.location, imageSegment: imageSegment)
                            
                            let width = abs(clampedCurrent.x - clampedStart.x)
                            let height = abs(clampedCurrent.y - clampedStart.y)
                            let x = min(clampedStart.x, clampedCurrent.x)
                            let y = min(clampedStart.y, clampedCurrent.y)
                            
                            currentBox = CGRect(x: x, y: y, width: width, height: height)
                        }
                        .onEnded { value in
                            if let box = currentBox, box.width > 20, box.height > 20 {
                                // Normalize relative to image segment, not container
                                let normalizedBox = CGRect(
                                    x: (box.origin.x - imageSegment.minX) / imageSegment.width,
                                    y: (box.origin.y - imageSegment.minY) / imageSegment.height,
                                    width: box.width / imageSegment.width,
                                    height: box.height / imageSegment.height
                                )
                                
                                // Get next available orderIndex
                                let nextOrderIndex = (document.segments.map { $0.orderIndex }.max() ?? -1) + 1
                                
                                let segment = Segment(
                                    imagePath: imagePath,
                                    boundingBox: normalizedBox,
                                    orderIndex: nextOrderIndex
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
    
    private func calculateImageSegment(containerSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        let segmentSize: CGSize
        if imageAspect > containerAspect {
            // Image is wider - fit to width
            segmentSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
        } else {
            // Image is taller - fit to height
            segmentSize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
        }
        
        let origin = CGPoint(
            x: (containerSize.width - segmentSize.width) / 2,
            y: (containerSize.height - segmentSize.height) / 2
        )
        
        return CGRect(origin: origin, size: segmentSize)
    }
    
    private func clampToImage(point: CGPoint, imageSegment: CGRect) -> CGPoint {
        return CGPoint(
            x: min(max(point.x, imageSegment.minX), imageSegment.maxX),
            y: min(max(point.y, imageSegment.minY), imageSegment.maxY)
        )
    }
    
    private var segmentsForCurrentImage: [Segment] {
        document.segments.filter { $0.imagePath == imagePath }
    }
    
    
    private func deleteSegment(_ segment: Segment) {
        // Only allow deletion of the last segment (highest orderIndex)
        let maxOrderIndex = document.segments.map { $0.orderIndex }.max() ?? -1
        
        guard segment.orderIndex == maxOrderIndex else {
            return  // Silently ignore deletion of non-last segments
        }
        
        // Remove the segment (no renumbering needed)
        if let index = document.segments.firstIndex(where: { $0.id == segment.id }) {
            document.segments.remove(at: index)
        }
    }
}
