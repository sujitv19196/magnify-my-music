//
//  EditorScrollView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import UIKit

/// Hosts SwiftUI content in a plain UIView with a two-finger bounding box gesture.
/// The live draft rectangle is drawn via CAShapeLayer directly on the UIKit layer
/// — no SwiftUI state changes occur during the gesture, keeping CPU low.
struct EditorScrollView<Content: View>: UIViewRepresentable {
    let onCommit: (CGRect) -> Void
    let content: Content

    init(
        onCommit: @escaping (CGRect) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onCommit = onCommit
        self.content = content()
    }

    func makeUIView(context: Context) -> UIView {
        let rootView = UIView()
        rootView.backgroundColor = .clear

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(host.view)
        context.coordinator.host = host

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: rootView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
        ])

        // CAShapeLayer for live draft rectangle — drawn in UIKit to avoid SwiftUI re-renders
        let draftLayer = CAShapeLayer()
        draftLayer.fillColor = UIColor.clear.cgColor
        draftLayer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.6).cgColor
        draftLayer.lineWidth = 3.0
        draftLayer.isHidden = true
        rootView.layer.addSublayer(draftLayer)
        context.coordinator.draftLayer = draftLayer

        let coordinator = context.coordinator
        let gr = TwoFingerBoxGestureRecognizer()
        gr.cancelsTouchesInView = false
        gr.delaysTouchesEnded = false
        gr.onChange = { [weak coordinator] rect in
            let path = UIBezierPath(rect: rect)
            coordinator?.draftLayer?.path = path.cgPath
            coordinator?.draftLayer?.isHidden = false
        }
        gr.onCommit = { [weak coordinator] rect in
            coordinator?.draftLayer?.isHidden = true
            coordinator?.draftLayer?.path = nil
            coordinator?.onCommit?(rect)
        }
        gr.onCancel = { [weak coordinator] in
            coordinator?.draftLayer?.isHidden = true
            coordinator?.draftLayer?.path = nil
        }
        rootView.addGestureRecognizer(gr)

        return rootView
    }

    func updateUIView(_ rootView: UIView, context: Context) {
        context.coordinator.host?.rootView = content
        context.coordinator.onCommit = onCommit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCommit: onCommit)
    }

    class Coordinator: NSObject {
        var host: UIHostingController<Content>?
        var draftLayer: CAShapeLayer?
        var onCommit: ((CGRect) -> Void)?

        init(onCommit: @escaping (CGRect) -> Void) {
            self.onCommit = onCommit
        }
    }
}
