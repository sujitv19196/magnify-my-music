//
//  FrameReaderView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit
import SwiftData

struct FrameReaderView: View {
    @Bindable var document: SheetMusicDocument
    @StateObject private var session: ReadingSession
    @State private var showToolPicker = false
    
    // Zoom state managed by UIScrollView
    @State private var zoomScale: CGFloat = 1.0
    
    // Frame sizing - leave room for toolbar
    private let frameHeightRatio: CGFloat = 0.85
    
    private let imageStore = ImageStore()
    
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
                        ForEach(session.playbackSequence) { frame in
                            if let image = try? imageStore.load(frame.imagePath) {
                                FrameView(
                                    frame: frame,
                                    image: image,
                                    tool: session.currentTool
                                )
                                .frame(height: geometry.size.height * frameHeightRatio)
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
    }
}

#Preview {
    let container = PreviewHelper.createPreviewContainer()
    let document = PreviewHelper.createSampleDocument(in: container)
    
    return NavigationStack {
        FrameReaderView(document: document)
    }
    .modelContainer(container)
}
