//
//  ZoomableScrollView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import UIKit

// Zoom configuration
private let minimumZoomScale: CGFloat = 0.1
private let maximumZoomScale: CGFloat = 10.0

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    @Binding var zoomScale: CGFloat
    
    init(zoomScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._zoomScale = zoomScale
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.backgroundColor = .clear
        
        // Host SwiftUI content in UIHostingController
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController
        
        // Store hosting controller reference
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update hosted content
        context.coordinator.hostingController?.rootView = content
        
        // Update zoom if changed externally
        if scrollView.zoomScale != zoomScale {
            scrollView.setZoomScale(zoomScale, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var zoomScale: CGFloat
        var hostingController: UIHostingController<Content>?
        
        init(zoomScale: Binding<CGFloat>) {
            self._zoomScale = zoomScale
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController?.view
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Update binding in real-time
            zoomScale = scrollView.zoomScale
        }
    }
}

