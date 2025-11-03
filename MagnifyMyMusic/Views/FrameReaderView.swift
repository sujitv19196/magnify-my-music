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
    
    // Local zoom state (resets each time view appears)
    @State private var currentZoom: CGFloat = 1.0
    @State private var totalZoom: CGFloat = 1.0
    
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
                    Spacer()
                    
                    Button {
                        showToolPicker.toggle()
                    } label: {
                        Image(systemName: "pencil.tip.crop.circle")
                            .font(.title2)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Scrollable, zoomable content
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 0) {
                        ForEach(document.frames) { frame in
                            if let image = try? imageStore.load(frame.imagePath) {
                                FrameView(
                                    frame: frame,
                                    image: image,
                                    tool: session.currentTool
                                )
                                .frame(height: geometry.size.height * 0.85)
                                .brightness(session.brightness)
                                .contrast(session.contrast)
                            }
                        }
                    }
                    .scaleEffect(totalZoom * currentZoom, anchor: .leading)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                currentZoom = value
                            }
                            .onEnded { value in
                                totalZoom *= value
                                currentZoom = 1.0
                            }
                    )
                }
                .onAppear {
                    totalZoom = 1.0  // Start at 1x, frames already sized to screen
                }
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
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
