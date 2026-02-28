//
//  EditorScrollView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import UIKit

/// A UIScrollView wrapper that enables pinch-to-zoom and two-finger panning
/// while leaving single-finger touches free for SwiftUI gestures (bounding box drawing).
struct EditorScrollView<Content: View>: UIViewRepresentable {
    @Binding var zoomScale: CGFloat
    let content: Content

    init(zoomScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._zoomScale = zoomScale
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        // Require two fingers to pan so single-finger drag reaches SwiftUI gestures
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(host.view)
        context.coordinator.host = host

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            host.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.host?.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var zoomScale: CGFloat
        var host: UIHostingController<Content>?

        init(zoomScale: Binding<CGFloat>) {
            self._zoomScale = zoomScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            host?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScale = scrollView.zoomScale
            centerContent(in: scrollView)
        }

        private func centerContent(in scrollView: UIScrollView) {
            guard let contentView = host?.view else { return }
            let contentSize = CGSize(
                width: contentView.frame.width * scrollView.zoomScale,
                height: contentView.frame.height * scrollView.zoomScale
            )
            let horizontal = max(0, (scrollView.bounds.width - contentSize.width) / 2)
            let vertical = max(0, (scrollView.bounds.height - contentSize.height) / 2)
            scrollView.contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        }
    }
}
