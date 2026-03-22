//
//  MarkerPlacementView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/28/26.
//

import SwiftUI

// MARK: - Clamped Position Modifier

private struct ClampedPositionModifier: ViewModifier {
    let x: CGFloat
    let y: CGFloat
    let minX: CGFloat
    let maxX: CGFloat

    @State private var contentWidth: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { contentWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in contentWidth = w }
            })
            .position(
                x: min(max(x, minX + contentWidth / 2), maxX - contentWidth / 2),
                y: y
            )
    }
}

private extension View {
    func clampedPosition(x: CGFloat, y: CGFloat, minX: CGFloat, maxX: CGFloat) -> some View {
        modifier(ClampedPositionModifier(x: x, y: y, minX: minX, maxX: maxX))
    }
}

/// Returns the CGRect (in container coordinates) where the image is rendered aspect-fit.
func calculateImageFrame(containerSize: CGSize, imageSize: CGSize) -> CGRect {
    let imageAspect = imageSize.width / imageSize.height
    let containerAspect = containerSize.width / containerSize.height
    let size: CGSize
    if imageAspect > containerAspect {
        size = CGSize(width: containerSize.width, height: containerSize.width / imageAspect)
    } else {
        size = CGSize(width: containerSize.height * imageAspect, height: containerSize.height)
    }
    let origin = CGPoint(
        x: (containerSize.width - size.width) / 2,
        y: (containerSize.height - size.height) / 2
    )
    return CGRect(origin: origin, size: size)
}

struct MarkerPlacementView: View {
    @Bindable var document: SheetMusicDocument
    let imagePath: String
    @Binding var selectedMarkerType: NavigationMarkerType?
    @Binding var editorSelection: EditorSelection

    @Environment(DocumentStore.self) var store
    @State private var cachedImage: UIImage?

    /// Last position where the finger lifted inside a valid segment.
    @State private var committedPosition: CGPoint? = nil
    /// Shared numeric config for parameterized marker types.
    @State private var configValue: Int? = nil

    var body: some View {
        GeometryReader { geometry in
            if let image = cachedImage {
                let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: image.size)

                let currentSeg = committedPosition.flatMap { segmentAt($0, imageFrame: imageFrame) }

                ZStack {
                    // ── Layer 0: UIKit drag overlay — draws live bar via CAShapeLayer,
                    //    zero SwiftUI re-renders during drag; commits position on finger lift.
                    // allowsHitTesting mirrors isActive so that when no marker type is selected,
                    // touches fall through to BoundingBoxEditorView's delete buttons below.
                    MarkerDragOverlay(
                        imageFrame: imageFrame,
                        segments: segmentsForCurrentImage,
                        isActive: selectedMarkerType != nil,
                        onCommit: { pos in committedPosition = pos }
                    )
                    .allowsHitTesting(selectedMarkerType != nil)

                    // ── Layer 1: saved markers ────────────────────────────
                    savedMarkersOverlay(imageFrame: imageFrame)
                        .allowsHitTesting(!editorSelection.isSegment)

                    // ── Layer 2: static bar at committed position (shown after finger lifts) ──
                    if let pos = committedPosition, let seg = currentSeg {
                        let segTop = imageFrame.minY + seg.boundingBoxY * imageFrame.height
                        let segH   = seg.boundingBoxHeight * imageFrame.height
                        Rectangle()
                            .fill(AppTheme.accent2.opacity(0.7))
                            .frame(width: AppTheme.markerBarWidth, height: segH)
                            .allowsHitTesting(false)
                            .position(x: pos.x, y: segTop + segH / 2)
                    }

                    // ── Layer 3 (top): action buttons (shown after finger lifts) ──
                    if let markerType = selectedMarkerType,
                       let pos = committedPosition,
                       let seg = currentSeg {
                        actionsPanel(
                            markerType: markerType,
                            position: pos,
                            segment: seg,
                            imageFrame: imageFrame
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: selectedMarkerType) { _, newType in
                    committedPosition = nil
                    if newType != nil {
                        editorSelection = .none
                    }
                    if let type = newType {
                        switch type {
                        case .repeatBackward, .volta: configValue = 1
                        default: configValue = nil
                        }
                    }
                }
            }
        }
        .task {
            cachedImage = try? store.loadImage(imagePath, from: document.id)
        }
    }

    // MARK: - Saved markers (vertical lines)

    @ViewBuilder
    private func savedMarkersOverlay(imageFrame: CGRect) -> some View {
        ForEach(segmentsForCurrentImage) { segment in
            let segTop = imageFrame.minY + segment.boundingBoxY * imageFrame.height
            let segH   = segment.boundingBoxHeight * imageFrame.height

            ForEach(segment.markers) { marker in
                let screenX = imageFrame.minX
                    + (segment.boundingBoxX + marker.xPosition * segment.boundingBoxWidth)
                    * imageFrame.width
                let isSelected = editorSelection == .marker(marker.id)

                // Vertical line with wider tap target
                ZStack {
                    Rectangle()
                        .fill(AppTheme.accent2.opacity(0.7))
                        .frame(width: AppTheme.markerBarWidth, height: segH)
                        .accessibilityHidden(true)

                    Color.clear
                        .frame(width: 44, height: segH)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                editorSelection = .marker(marker.id)
                        }
                }
                .position(x: screenX, y: segTop + segH / 2)

                // Label + delete badge — only shown when selected
                if isSelected {
                    HStack(spacing: 6) {
                        Text(marker.type.displayName)
                            .font(AppTheme.labelFont)
                            .foregroundStyle(.primary)
                        Button {
                            deleteMarker(marker, from: segment)
                            editorSelection = .none
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Delete \(marker.type.displayName) marker")
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .fixedSize()
                    .clampedPosition(
                        x: screenX,
                        y: segTop - 24,
                        minX: imageFrame.minX,
                        maxX: imageFrame.maxX
                    )
                }
            }
        }
    }

    // MARK: - Action panel (below the bar)

    @ViewBuilder
    private func actionsPanel(
        markerType: NavigationMarkerType,
        position: CGPoint,
        segment: Segment,
        imageFrame: CGRect
    ) -> some View {
        let segTop  = imageFrame.minY + segment.boundingBoxY * imageFrame.height
        let segH    = segment.boundingBoxHeight * imageFrame.height
        let barBotY = segTop + segH

        let canSave = isConfigValid(for: markerType)

        HStack(spacing: 10) {
            // Numeric config for parameterised types
            if let n = configValue {
                HStack(spacing: 4) {
                    Text(configDisplayString(markerType: markerType, value: n))
                        .font(AppTheme.bodyFont)
                        .monospacedDigit()
                    Stepper(
                        configLabel(for: markerType),
                        value: Binding(get: { n }, set: { configValue = $0 })
                    )
                    .labelsHidden()
                    .fixedSize()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
            }

            Button("Save") {
                saveMarker(at: position, imageFrame: imageFrame)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)

            Button {
                selectedMarkerType = nil
            } label: {
                Text("Cancel")
                    .font(AppTheme.labelFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.secondary))
            }
            .accessibilityLabel("Cancel marker placement")
            .buttonStyle(.plain)
        }
        .fixedSize()
        // Centre the panel on the bar's X, clamped to stay within image bounds
        .clampedPosition(
            x: position.x,
            y: barBotY + 30,
            minX: imageFrame.minX,
            maxX: imageFrame.maxX
        )
    }

    // MARK: - Helpers

    private func segmentAt(_ screenPoint: CGPoint, imageFrame: CGRect) -> Segment? {
        let normX = (screenPoint.x - imageFrame.minX) / imageFrame.width
        let normY = (screenPoint.y - imageFrame.minY) / imageFrame.height
        return segmentsForCurrentImage.first {
            $0.boundingBox.contains(CGPoint(x: normX, y: normY))
        }
    }

    private func configLabel(for type: NavigationMarkerType) -> String {
        switch type {
        case .repeatBackward: return "×"
        case .volta:          return "Ending"
        default:              return ""
        }
    }

    /// Display string for the numeric config (e.g. "× 2" for repeat, "1st ending" for volta).
    private func configDisplayString(markerType: NavigationMarkerType, value n: Int) -> String {
        switch markerType {
        case .repeatBackward: return "Repeat \(n)x"
        case .volta:          return "\(n.ordinalString) Ending"
        default:              return ""
        }
    }

    private func isConfigValid(for type: NavigationMarkerType) -> Bool {
        switch type {
        case .repeatBackward, .volta: return configValue != nil
        default: return true
        }
    }

    private func deleteMarker(_ marker: NavigationMarker, from segment: Segment) {
        segment.markers.removeAll { $0.id == marker.id }
        try? store.save(document)
    }

    private func saveMarker(at screenPoint: CGPoint, imageFrame: CGRect) {
        guard let markerType = selectedMarkerType,
              let segment = segmentAt(screenPoint, imageFrame: imageFrame) else { return }
        let normX = (screenPoint.x - imageFrame.minX) / imageFrame.width
        let xPosition = (normX - segment.boundingBoxX) / segment.boundingBoxWidth

        let finalType: NavigationMarkerType
        switch markerType {
        case .repeatBackward:
            finalType = .repeatBackward(times: configValue ?? 1)
        case .volta:
            finalType = .volta(numbers: [configValue ?? 1])
        default:
            finalType = markerType
        }

        let newMarker = NavigationMarker(type: finalType, xPosition: xPosition)
        segment.markers.append(newMarker)
        try? store.save(document)
        selectedMarkerType = nil
        editorSelection = .marker(newMarker.id)
    }

    private var segmentsForCurrentImage: [Segment] {
        document.segments.filter { $0.imagePath == imagePath }
    }
}
