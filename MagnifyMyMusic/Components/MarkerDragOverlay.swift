//
//  MarkerDragOverlay.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 3/8/26.
//

import SwiftUI
import UIKit

/// Handles single-finger marker drag entirely in UIKit.
/// The live vertical bar is drawn via CAShapeLayer — no SwiftUI state changes
/// during the drag, so MarkerPlacementView never re-renders while the finger moves.
struct MarkerDragOverlay: UIViewRepresentable {
    let imageFrame: CGRect
    let segments: [Segment]
    let isActive: Bool
    /// Called once when the finger lifts inside a valid segment.
    let onCommit: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false

        let barLayer = CAShapeLayer()
        barLayer.fillColor = UIColor(AppTheme.accent2).withAlphaComponent(0.7).cgColor
        barLayer.strokeColor = UIColor.clear.cgColor
        barLayer.isHidden = true
        view.layer.addSublayer(barLayer)
        context.coordinator.barLayer = barLayer

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        pan.isEnabled = isActive
        view.addGestureRecognizer(pan)
        context.coordinator.panRecognizer = pan

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.isEnabled = isActive
        view.addGestureRecognizer(tap)
        context.coordinator.tapRecognizer = tap

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.imageFrame = imageFrame
        context.coordinator.segments = segments
        context.coordinator.onCommit = onCommit
        context.coordinator.panRecognizer?.isEnabled = isActive
        context.coordinator.tapRecognizer?.isEnabled = isActive
        // When not placing a marker, make the view fully transparent to touches
        // so delete buttons in BoundingBoxEditorView remain tappable.
        uiView.isUserInteractionEnabled = isActive
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(imageFrame: imageFrame, segments: segments, onCommit: onCommit)
    }

    class Coordinator: NSObject {
        var imageFrame: CGRect
        var segments: [Segment]
        var onCommit: (CGPoint) -> Void
        var barLayer: CAShapeLayer?
        weak var panRecognizer: UIPanGestureRecognizer?
        weak var tapRecognizer: UITapGestureRecognizer?

        init(imageFrame: CGRect, segments: [Segment], onCommit: @escaping (CGPoint) -> Void) {
            self.imageFrame = imageFrame
            self.segments = segments
            self.onCommit = onCommit
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard let view = gr.view else { return }
            let point = gr.location(in: view)
            if segmentAt(point) != nil {
                onCommit(point)
            }
        }

        @objc func handlePan(_ gr: UIPanGestureRecognizer) {
            guard let view = gr.view else { return }
            let point = gr.location(in: view)

            switch gr.state {
            case .changed, .began:
                updateBar(at: point)
            case .ended:
                barLayer?.isHidden = true
                if segmentAt(point) != nil {
                    onCommit(point)
                }
            case .cancelled, .failed:
                barLayer?.isHidden = true
            default:
                break
            }
        }

        private func updateBar(at point: CGPoint) {
            guard let seg = segmentAt(point) else {
                barLayer?.isHidden = true
                return
            }
            let segTop = imageFrame.minY + seg.boundingBoxY * imageFrame.height
            let segH   = seg.boundingBoxHeight * imageFrame.height
            let barW   = AppTheme.markerBarWidth
            let rect   = CGRect(x: point.x - barW / 2, y: segTop, width: barW, height: segH)
            barLayer?.path = UIBezierPath(rect: rect).cgPath
            barLayer?.isHidden = false
        }

        private func segmentAt(_ point: CGPoint) -> Segment? {
            let normX = (point.x - imageFrame.minX) / imageFrame.width
            let normY = (point.y - imageFrame.minY) / imageFrame.height
            return segments.first {
                $0.boundingBox.contains(CGPoint(x: normX, y: normY))
            }
        }
    }
}
