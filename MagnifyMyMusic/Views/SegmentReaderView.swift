//
//  SegmentReaderView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit

struct SegmentReaderView: View {
    @Bindable var document: SheetMusicDocument
    @StateObject private var session: ReadingSession
    @Environment(DocumentStore.self) var store
    @State private var showToolPicker = false
    
    // Zoom state managed by UIScrollView
    @State private var zoomScale: CGFloat = 1.0
    
    // Segment sizing - leave room for toolbar
    private let segmentHeightRatio: CGFloat = 0.85
    
    init(document: SheetMusicDocument) {
        self._document = Bindable(wrappedValue: document)
        self._session = StateObject(wrappedValue: ReadingSession(document: document))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Minimal toolbar
                HStack {
                    NavigationLink {
                        DocumentEditorView(document: document)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        showToolPicker.toggle()
                    } label: {
                        Image(systemName: "pencil.tip.crop.circle")
                            .font(.title2)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                
                // Scrollable, zoomable content using UIScrollView
                ZoomableScrollView(zoomScale: $zoomScale) {
                    HStack(spacing: 0) {
                        ForEach(session.playbackSequence) { step in
                            if let image = try? store.loadImage(step.segment.imagePath, from: document.id) {
                                SegmentView(
                                    segment: step.segment,
                                    image: image,
                                    tool: session.currentTool
                                )
                                .frame(height: geometry.size.height * segmentHeightRatio)
                            }
                        }
                    }
                }
                .onAppear {
                    session.buildPlaybackSequence()
                    zoomScale = 1.0  // Start at 1x
                }
            }
        }
        .sheet(isPresented: $showToolPicker) {
            DrawingToolPickerView(currentTool: $session.currentTool)
        }
        .onKeyPress(.space) {
            session.advanceByPedal()
            return .handled
        }
        .onDisappear {
            try? store.save(document)
        }
    }
}

#Preview {
    let store = PreviewHelper.createPreviewStore()
    let doc = PreviewHelper.createSampleDocument()
    
    return NavigationStack {    
        SegmentReaderView(document: doc)
    }
    .environment(store)
}
