//
//  MarkerPlacementView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/28/26.
//

import SwiftUI

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

    @Environment(DocumentStore.self) var store

    /// Live finger position while the gesture is active; resets to nil on lift.
    @GestureState private var liveLocation: CGPoint? = nil
    /// Last position where the finger lifted inside a valid segment.
    @State private var committedPosition: CGPoint? = nil
    /// Shared numeric config for parameterized marker types.
    @State private var configValue: Int? = nil

    var body: some View {
        GeometryReader { geometry in
            if let image = try? store.loadImage(imagePath, from: document.id) {
                let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: image.size)

                let currentPos = liveLocation ?? committedPosition
                let currentSeg = currentPos.flatMap { segmentAt($0, imageFrame: imageFrame) }

                ZStack {
                    // ── Layer 0 (bottom): gesture capture ─────────────────
                    // Sits below everything so saved-marker buttons and action
                    // buttons (higher layers) always win over this gesture.
                    if selectedMarkerType != nil {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .updating($liveLocation) { value, state, _ in
                                        guard selectedMarkerType != nil else { return }
                                        state = value.location
                                    }
                                    .onEnded { value in
                                        guard selectedMarkerType != nil else { return }
                                        let loc = value.location
                                        if segmentAt(loc, imageFrame: imageFrame) != nil {
                                            committedPosition = loc
                                        }
                                    }
                            )
                    }

                    // ── Layer 1: saved markers ────────────────────────────
                    savedMarkersOverlay(imageFrame: imageFrame)

                    // ── Layer 2: placement hint ───────────────────────────
                    if selectedMarkerType != nil, currentPos == nil {
                        Text("Tap or drag within a segment to place")
                            .font(AppTheme.hintFont)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                    }

                    // ── Layer 3: pending bar visual (no hit testing) ──────
                    if let pos = currentPos, let seg = currentSeg {
                        let liveX  = liveLocation?.x ?? pos.x
                        let segTop = imageFrame.minY + seg.boundingBoxY * imageFrame.height
                        let segH   = seg.boundingBoxHeight * imageFrame.height

                        Rectangle()
                            .fill(AppTheme.accent2.opacity(0.7))
                            .frame(width: AppTheme.markerBarWidth, height: segH)
                            .allowsHitTesting(false)
                            .position(x: liveX, y: segTop + segH / 2)
                    }

                    // ── Layer 4 (top): action buttons ─────────────────────
                    // Rendered last so they receive touches before lower layers.
                    if let markerType = selectedMarkerType,
                       let pos = currentPos,
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
                    if let type = newType {
                        switch type {
                        case .repeatBackward, .volta: configValue = 1
                        default: configValue = nil
                        }
                    }
                }
            }
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

                // Vertical line
                Rectangle()
                    .fill(AppTheme.accent2.opacity(0.7))
                    .frame(width: AppTheme.markerBarWidth, height: segH)
                    .accessibilityHidden(true)
                    .position(x: screenX, y: segTop + segH / 2)

                // Label + delete badge at top of line
                HStack(spacing: 4) {
                    Text(marker.type.displayName)
                        .font(AppTheme.labelFont)
                        .foregroundStyle(.primary)
                    Button {
                        deleteMarker(marker, from: segment)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Delete \(marker.type.displayName) marker")
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .fixedSize()
                .position(x: screenX - 72, y: segTop + 22)
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
        let liveX   = liveLocation?.x ?? position.x
        let segTop  = imageFrame.minY + segment.boundingBoxY * imageFrame.height
        let segH    = segment.boundingBoxHeight * imageFrame.height
        let barBotY = segTop + segH

        let isCommitted = liveLocation == nil && committedPosition != nil
        let canSave = isCommitted && isConfigValid(for: markerType)

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
                saveMarker(at: CGPoint(x: liveX, y: position.y), imageFrame: imageFrame)
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
        // Centre the panel on the bar's X, 12 pt below the bar bottom
        .position(x: liveX, y: barBotY + 30)
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

        segment.markers.append(NavigationMarker(type: finalType, xPosition: xPosition))
        selectedMarkerType = nil
    }

    private var segmentsForCurrentImage: [Segment] {
        document.segments.filter { $0.imagePath == imagePath }
    }
}
