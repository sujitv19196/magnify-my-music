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
    
    @State private var currentBox: CGRect?
    @State private var dragStart: CGPoint = .zero
    
    private let imageStore = ImageStore()
    
    var body: some View {
        GeometryReader { geometry in
            if let image = try? imageStore.load(imagePath) {
                let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: image.size)
                
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    let maxOrderIndex = document.frames.map { $0.orderIndex }.max() ?? -1
                    
                    ForEach(framesForCurrentImage) { frame in
                        let boxWidth = frame.boundingBoxWidth * imageFrame.width
                        let boxHeight = frame.boundingBoxHeight * imageFrame.height
                        let boxX = imageFrame.minX + frame.boundingBoxX * imageFrame.width
                        let boxY = imageFrame.minY + frame.boundingBoxY * imageFrame.height
                        let isLastFrame = frame.orderIndex == maxOrderIndex
                        
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: boxWidth, height: boxHeight)
                            .overlay(alignment: .leading) {
                                // Frame number - center left of box
                                Text("\(frame.orderIndex + 1)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                                    .offset(x: -40)
                            }
                            .overlay(alignment: .trailing) {
                                // Delete button - center right of box (only for last frame)
                                if isLastFrame {
                                    Button {
                                        deleteFrame(frame)
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
                            .id("\(frame.id)-\(frame.orderIndex)")
                    }
                    .drawingGroup()  // Composite frames into single GPU layer for better performance
                    
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
                                
                                // Get next available orderIndex
                                let nextOrderIndex = (document.frames.map { $0.orderIndex }.max() ?? -1) + 1
                                
                                let frame = Frame(
                                    imagePath: imagePath,
                                    boundingBox: normalizedBox,
                                    orderIndex: nextOrderIndex
                                )
                                
                                document.frames.append(frame)
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
    }
    
    private func calculateImageFrame(containerSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        let frameSize: CGSize
        if imageAspect > containerAspect {
            // Image is wider - fit to width
            frameSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
        } else {
            // Image is taller - fit to height
            frameSize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
        }
        
        let origin = CGPoint(
            x: (containerSize.width - frameSize.width) / 2,
            y: (containerSize.height - frameSize.height) / 2
        )
        
        return CGRect(origin: origin, size: frameSize)
    }
    
    private func clampToImage(point: CGPoint, imageFrame: CGRect) -> CGPoint {
        return CGPoint(
            x: min(max(point.x, imageFrame.minX), imageFrame.maxX),
            y: min(max(point.y, imageFrame.minY), imageFrame.maxY)
        )
    }
    
    private var framesForCurrentImage: [Frame] {
        document.frames.filter { $0.imagePath == imagePath }
    }
    
    
    private func deleteFrame(_ frame: Frame) {
        // Only allow deletion of the last frame (highest orderIndex)
        let maxOrderIndex = document.frames.map { $0.orderIndex }.max() ?? -1
        
        guard frame.orderIndex == maxOrderIndex else {
            return  // Silently ignore deletion of non-last frames
        }
        
        // Remove the frame (no renumbering needed)
        if let index = document.frames.firstIndex(where: { $0.id == frame.id }) {
            document.frames.remove(at: index)
        }
    }
}

