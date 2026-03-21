//
//  BoundingBoxEditorView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

private enum Edge: CaseIterable {
    case top, bottom, leading, trailing
}

struct BoundingBoxEditorView: View {
    @Bindable var document: SheetMusicDocument
    let imagePath: String

    @Binding var committedBox: CGRect?
    @Binding var editorSelection: EditorSelection

    @Environment(DocumentStore.self) var store
    @State private var cachedImage: UIImage?
    @State private var dragStartBox: CGRect? = nil
    /// Absolute X positions of markers (in normalized image coords) captured at drag start.
    @State private var dragStartMarkerAbsX: [UUID: Double] = [:]

    var body: some View {
        GeometryReader { geometry in
            if let image = cachedImage {
                let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: image.size)

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editorSelection = .none
                        }

                    ForEach(segmentsForCurrentImage) { segment in
                        let boxWidth = segment.boundingBoxWidth * imageFrame.width
                        let boxHeight = segment.boundingBoxHeight * imageFrame.height
                        let boxX = imageFrame.minX + segment.boundingBoxX * imageFrame.width
                        let boxY = imageFrame.minY + segment.boundingBoxY * imageFrame.height
                        let isSelected = editorSelection == .segment(segment.id)

                        Rectangle()
                            .stroke(AppTheme.accent1, lineWidth: isSelected ? AppTheme.boundingBoxStrokeWidth * 2 : AppTheme.boundingBoxStrokeWidth)
                            .frame(width: boxWidth, height: boxHeight)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editorSelection = .segment(segment.id)
                            }
                            .overlay(alignment: .topTrailing) {
                                if isSelected {
                                    Button {
                                        deleteSegment(segment)
                                        editorSelection = .none
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(AppTheme.displayFont)
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .accessibilityLabel("Delete segment")
                                    .offset(x: 16, y: -24)
                                }
                            }
                            .overlay {
                                if isSelected {
                                    ForEach(Edge.allCases, id: \.self) { edge in
                                        let isHorizontal = (edge == .top || edge == .bottom)
                                        Capsule()
                                            .fill(Color.white)
                                            .overlay(Capsule().stroke(AppTheme.accent1, lineWidth: 2))
                                            .frame(width: isHorizontal ? 40 : 14,
                                                   height: isHorizontal ? 14 : 40)
                                            .contentShape(Rectangle().scale(1.5))
                                            .position(edgeHandlePosition(edge, boxWidth: boxWidth, boxHeight: boxHeight))
                                            .gesture(
                                                DragGesture(coordinateSpace: .named("editorZStack"))
                                                    .onChanged { value in
                                                        if dragStartBox == nil {
                                                            dragStartBox = segment.boundingBox
                                                            dragStartMarkerAbsX = Dictionary(uniqueKeysWithValues:
                                                                segment.markers.map { marker in
                                                                    (marker.id, segment.boundingBoxX + marker.xPosition * segment.boundingBoxWidth)
                                                                }
                                                            )
                                                        }
                                                        resizeSegment(segment, edge: edge,
                                                                      startLocation: value.startLocation,
                                                                      currentLocation: value.location,
                                                                      imageFrame: imageFrame)
                                                    }
                                                    .onEnded { _ in
                                                        dragStartBox = nil
                                                        dragStartMarkerAbsX = [:]
                                                        try? store.save(document)
                                                    }
                                            )
                                    }
                                }
                            }
                            .position(x: boxX + boxWidth / 2, y: boxY + boxHeight / 2)
                            .zIndex(isSelected ? 1 : 0)
                            .id(segment.id)
                    }

                }
                .coordinateSpace(name: "editorZStack")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: committedBox) { _, newBox in
                    guard let box = newBox else { return }
                    let clamped = clampToImage(rect: box, imageFrame: imageFrame)
                    if clamped.width > 20, clamped.height > 20 {
                        let normalizedBox = CGRect(
                            x: (clamped.minX - imageFrame.minX) / imageFrame.width,
                            y: (clamped.minY - imageFrame.minY) / imageFrame.height,
                            width: clamped.width / imageFrame.width,
                            height: clamped.height / imageFrame.height
                        )
                        let segment = Segment(imagePath: imagePath, boundingBox: normalizedBox)
                        document.segments.append(segment)
                        try? store.save(document)
                        editorSelection = .segment(segment.id)
                    }
                    committedBox = nil
                }
            }
        }
        .task {
            cachedImage = try? store.loadImage(imagePath, from: document.id)
        }
        .onDisappear {
            try? store.save(document)
        }
    }

    private func clampToImage(rect: CGRect, imageFrame: CGRect) -> CGRect {
        let x = max(rect.minX, imageFrame.minX)
        let y = max(rect.minY, imageFrame.minY)
        let maxX = min(rect.maxX, imageFrame.maxX)
        let maxY = min(rect.maxY, imageFrame.maxY)
        return CGRect(x: x, y: y, width: max(0, maxX - x), height: max(0, maxY - y))
    }

    private var segmentsForCurrentImage: [Segment] {
        document.segments.filter { $0.imagePath == imagePath }
    }

    private func deleteSegment(_ segment: Segment) {
        if let index = document.segments.firstIndex(where: { $0.id == segment.id }) {
            document.segments.remove(at: index)
            try? store.save(document)
        }
    }

    // MARK: - Resize helpers

    private func edgeHandlePosition(_ edge: Edge, boxWidth: CGFloat, boxHeight: CGFloat) -> CGPoint {
        switch edge {
        case .top:      return CGPoint(x: boxWidth / 2, y: 0)
        case .bottom:   return CGPoint(x: boxWidth / 2, y: boxHeight)
        case .leading:  return CGPoint(x: 0, y: boxHeight / 2)
        case .trailing: return CGPoint(x: boxWidth, y: boxHeight / 2)
        }
    }

    private func resizeSegment(_ segment: Segment, edge: Edge,
                               startLocation: CGPoint, currentLocation: CGPoint,
                               imageFrame: CGRect) {
        guard let start = dragStartBox else { return }

        // Compute delta in normalized coordinates using absolute positions in the stable coordinate space
        let dx = (currentLocation.x - startLocation.x) / imageFrame.width
        let dy = (currentLocation.y - startLocation.y) / imageFrame.height
        let minNormW: CGFloat = 20 / imageFrame.width
        let minNormH: CGFloat = 20 / imageFrame.height

        var newBox = start

        switch edge {
        case .top:
            let clampedDy = min(dy, start.height - minNormH)
            newBox.origin.y = start.origin.y + clampedDy
            newBox.size.height = start.height - clampedDy

        case .bottom:
            newBox.size.height = max(start.height + dy, minNormH)

        case .leading:
            let clampedDx = min(dx, start.width - minNormW)
            newBox.origin.x = start.origin.x + clampedDx
            newBox.size.width = start.width - clampedDx

        case .trailing:
            newBox.size.width = max(start.width + dx, minNormW)
        }

        // Clamp to image bounds (normalized 0–1)
        newBox.origin.x = max(0, newBox.origin.x)
        newBox.origin.y = max(0, newBox.origin.y)
        if newBox.maxX > 1 { newBox.size.width = 1 - newBox.origin.x }
        if newBox.maxY > 1 { newBox.size.height = 1 - newBox.origin.y }

        segment.boundingBox = newBox

        // Recalculate marker xPositions to preserve their absolute image positions
        if edge == .leading || edge == .trailing {
            for marker in segment.markers {
                if let absX = dragStartMarkerAbsX[marker.id], newBox.width > 0 {
                    marker.xPosition = (absX - newBox.origin.x) / newBox.width
                }
            }
        }
    }
}
