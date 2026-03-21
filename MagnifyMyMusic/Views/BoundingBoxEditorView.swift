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

    @Binding var committedBox: CGRect?
    @Binding var editorSelection: EditorSelection

    @Environment(DocumentStore.self) var store
    @State private var cachedImage: UIImage?

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
                            withAnimation(.easeInOut(duration: 0.15)) {
                                editorSelection = .none
                            }
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
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    editorSelection = .segment(segment.id)
                                }
                            }
                            .overlay(alignment: .top) {
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
                                    .offset(y: -24)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .position(x: boxX + boxWidth / 2, y: boxY + boxHeight / 2)
                            .id(segment.id)
                    }

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: committedBox) { _, newBox in
                    editorSelection = .none
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
}
