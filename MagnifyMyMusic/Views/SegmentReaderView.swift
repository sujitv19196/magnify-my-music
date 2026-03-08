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
    @State private var showToolPicker = false
    @State private var showScrollSettings = false

    init(document: SheetMusicDocument) {
        self._document = Bindable(wrappedValue: document)
        self._session = State(wrappedValue: ReadingSession(document: document))
    }

    var body: some View {
        GeometryReader { geometry in
            ZoomableScrollView(zoomScale: Bindable(session).zoomScale) {
                HStack(spacing: 0) {
                    ForEach(session.playbackSequence) { step in
                        if let image = try? store.loadImage(step.segment.imagePath, from: document.id) {
                            SegmentView(
                                segment: step.segment,
                                image: image,
                                tool: session.currentTool,
                                startX: step.startX,
                                endX: step.endX
                            )
                            .frame(height: geometry.size.height)
                        }
                    }
                }
            }
            .onAppear {
                session.buildPlaybackSequence()
            }
        }
        .navigationBarBackButtonHidden(true)
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
                        Text("Pages")
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
            .presentationDetents([.height(200)])
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
