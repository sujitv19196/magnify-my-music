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
    @State private var session: ReadingSession
    @Environment(DocumentStore.self) var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissToRoot) private var dismissToRoot
    @State private var stepImageCache: [UUID: UIImage] = [:]
    @State private var showToolPicker = false
    @State private var showScrollSettings = false
    @State private var toolbarVisible = true

    init(document: SheetMusicDocument) {
        self._document = Bindable(wrappedValue: document)
        self._session = State(wrappedValue: ReadingSession(document: document))
    }

    var body: some View {
        GeometryReader { geometry in
            ZoomableScrollView(zoomScale: Bindable(session).zoomScale, isScrollEnabled: !session.fingerDrawingEnabled) {
                HStack(spacing: 0) {
                    ForEach(session.playbackSequence) { step in
                        if let image = stepImageCache[step.id] {
                            SegmentView(
                                segment: step.segment,
                                image: image,
                                tool: session.currentTool,
                                drawingPolicy: session.fingerDrawingEnabled ? .anyInput : .pencilOnly
                            )
                            .frame(height: geometry.size.height)
                        }
                    }
                }
            }
            .onTapGesture {
                withAnimation { toolbarVisible.toggle() }
            }
            .onAppear {
                session.buildPlaybackSequence()
                var pageImages: [String: UIImage] = [:]
                var stepCache: [UUID: UIImage] = [:]
                for step in session.playbackSequence {
                    let path = step.segment.imagePath
                    if pageImages[path] == nil {
                        pageImages[path] = try? store.loadImage(path, from: document.id)
                    }
                    guard let pageImage = pageImages[path] else { continue }
                    let box = step.segment.boundingBox
                    let cropRect = CGRect(
                        x: box.minX + step.startX * box.width,
                        y: box.minY,
                        width: (step.endX - step.startX) * box.width,
                        height: box.height
                    )
                    if let cropped = pageImage.cropped(to: cropRect) {
                        stepCache[step.id] = cropped
                    }
                }
                stepImageCache = stepCache
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(toolbarVisible ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 16) {
                    Button {
                        dismissToRoot()
                    } label: {
                        Text("Library")
                            .font(AppTheme.labelFont)
                    }
                    .accessibilityLabel("Return to library")
                    Button {
                        dismiss()
                    } label: {
                        Text("Edit")
                            .font(AppTheme.labelFont)
                    }
                    .accessibilityLabel("Return to page editor")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showScrollSettings.toggle()
                } label: {
                    Image(systemName: "arrow.right.to.line")
                        .font(.title2)
                }
                .accessibilityLabel("Adjust pedal scroll distance")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    session.fingerDrawingEnabled.toggle()
                } label: {
                    Image(systemName: session.fingerDrawingEnabled ? "hand.draw.fill" : "hand.draw")
                        .font(.title2)
                }
                .accessibilityLabel(session.fingerDrawingEnabled ? "Disable finger drawing" : "Enable finger drawing")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showToolPicker.toggle()
                } label: {
                    Image(systemName: "pencil.tip.crop.circle")
                        .font(.title2)
                }
                .accessibilityLabel("Open drawing tool picker")
            }
        }
        .sheet(isPresented: $showToolPicker) {
            DrawingToolPickerView(currentTool: $session.currentTool)
        }
        .background {
            KeyCommandOverlay(
                onAdvance: { session.advanceByPedal() },
                onRetreat: { session.retreatByPedal() }
            )
            .frame(width: 0, height: 0)
        }
        .sheet(isPresented: $showScrollSettings) {
            VStack(spacing: 24) {
                Text("Pedal Scroll Distance")
                    .font(.headline)
                Text("\(Int(session.pedalScrollDistance)) pt")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Slider(
                    value: Bindable(session).pedalScrollDistance,
                    in: 50...800,
                    step: 10
                )
                .padding(.horizontal)
            }
            .padding()
            .presentationDetents([.height(140)])
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
