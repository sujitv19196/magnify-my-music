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

    /// Committed dot position (updated on each drag end).
    @State private var dotPosition: CGPoint = .zero
    /// Live drag delta — auto-resets to .zero when the gesture ends.
    @GestureState private var dragOffset: CGSize = .zero

    /// Shared numeric config value for parameterized marker types (volta number or repeat times).
    @State private var configValue: Int? = nil

    var body: some View {
        GeometryReader { geometry in
            if let image = try? store.loadImage(imagePath, from: document.id) {
                let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: image.size)
                ZStack {
                    savedMarkersOverlay(imageFrame: imageFrame)

                    if let markerType = selectedMarkerType {
                        pendingDotOverlay(markerType: markerType, imageFrame: imageFrame)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: selectedMarkerType) { _, newType in
                    if newType != nil {
                        dotPosition = CGPoint(x: imageFrame.midX, y: imageFrame.midY)
                        // Configurable types default to 1 so the stepper is shown immediately.
                        switch newType! {
                        case .repeatBackward, .volta: configValue = 1
                        default: configValue = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Saved markers

    @ViewBuilder
    private func savedMarkersOverlay(imageFrame: CGRect) -> some View {
        ForEach(segmentsForCurrentImage) { segment in
            ForEach(segment.markers) { marker in
                let screenX = imageFrame.minX
                    + (segment.boundingBoxX + marker.xPosition * segment.boundingBoxWidth)
                    * imageFrame.width
                let screenY = imageFrame.minY
                    + (segment.boundingBoxY + segment.boundingBoxHeight / 2.0)
                    * imageFrame.height

                savedMarkerBadge(marker: marker, segment: segment,
                                 at: CGPoint(x: screenX, y: screenY))
            }
        }
    }

    @ViewBuilder
    private func savedMarkerBadge(marker: NavigationMarker, segment: Segment, at point: CGPoint) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                Text(marker.type.displayName)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.leading, 10)
                    .padding(.vertical, 5)

                Button {
                    deleteMarker(marker, from: segment)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white).padding(1))
                }
                .padding(.trailing, 6)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .shadow(color: .secondary.opacity(0.5), radius: 3, y: 1)
            )

            Circle()
                .fill(Color.accentColor)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1.5))
        }
        .position(x: point.x, y: point.y - 28)
    }

    // MARK: - Pending dot (being placed)

    @ViewBuilder
    private func pendingDotOverlay(markerType: NavigationMarkerType, imageFrame: CGRect) -> some View {
        let live = CGPoint(
            x: dotPosition.x + dragOffset.width,
            y: dotPosition.y + dragOffset.height
        )
        let inSegment = containingSegment(for: live, imageFrame: imageFrame) != nil
        let configOK = isConfigValid(for: markerType)
        let canSave = inSegment && configOK

        // Taller offset when the config row is visible so the overlay doesn't overlap the dot.
        let hasConfigRow = requiresConfig(markerType)
        let yOffset: CGFloat = hasConfigRow ? -82 : -56

        VStack(spacing: 8) {
            // Numeric config row — only for parameterized types
            if case .repeatBackward = markerType {
                numericConfigRow(label: "×", prompt: "Set repeat count")
            } else if case .volta = markerType {
                numericConfigRow(label: "Ending", prompt: "Set ending number")
            }

            // Action bar
            HStack(spacing: 10) {
                Text(markerType.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentColor))

                Button {
                    saveMarker(at: live, imageFrame: imageFrame)
                } label: {
                    Text("Save")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(canSave ? Color.accentColor : Color.secondary))
                }
                .disabled(!canSave)
                .buttonStyle(.plain)

                Button { selectedMarkerType = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                }
            }
        }
        .position(x: live.x, y: live.y + yOffset)

        // Draggable dot — positioned at `live` so the gesture coordinate space never shifts as the view moves.
        Circle()
            .fill(Color.accentColor)
            .frame(width: 34, height: 34)
            .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 2.5))
            .shadow(color: .secondary.opacity(0.4), radius: 4, y: 2)
            .position(x: live.x, y: live.y)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        dotPosition.x += value.translation.width
                        dotPosition.y += value.translation.height
                    }
            )
    }

    /// A compact row that shows a "set number" prompt when unset, or a Stepper once the user taps in.
    @ViewBuilder
    private func numericConfigRow(label: String, prompt: String) -> some View {
        Group {
            if let n = configValue {
                HStack(spacing: 6) {
                    Text("\(label) \(n)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Stepper(
                        "\(label) \(n)",
                        value: Binding(get: { n }, set: { configValue = $0 }),
                        in: 1...8
                    )
                    .labelsHidden()
                    .fixedSize()
                }
            } else {
                Button {
                    configValue = 1
                } label: {
                    Label(prompt, systemImage: "number.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(uiColor: .systemBackground).opacity(0.95))
                .shadow(color: .secondary.opacity(0.3), radius: 3, y: 1)
        )
    }

    // MARK: - Helpers

    private func requiresConfig(_ type: NavigationMarkerType) -> Bool {
        switch type {
        case .repeatBackward, .volta: return true
        default: return false
        }
    }

    private func isConfigValid(for type: NavigationMarkerType) -> Bool {
        switch type {
        case .repeatBackward, .volta: return configValue != nil
        default: return true
        }
    }

    private func containingSegment(for screenPoint: CGPoint, imageFrame: CGRect) -> Segment? {
        let normX = (screenPoint.x - imageFrame.minX) / imageFrame.width
        let normY = (screenPoint.y - imageFrame.minY) / imageFrame.height
        return segmentsForCurrentImage.first {
            $0.boundingBox.contains(CGPoint(x: normX, y: normY))
        }
    }

    private func deleteMarker(_ marker: NavigationMarker, from segment: Segment) {
        segment.markers.removeAll { $0.id == marker.id }
    }

    private func saveMarker(at screenPoint: CGPoint, imageFrame: CGRect) {
        guard let markerType = selectedMarkerType,
              let segment = containingSegment(for: screenPoint, imageFrame: imageFrame) else { return }
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
