//
//  PageEditorView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

struct PageEditorView: View {
    @Bindable var document: SheetMusicDocument
    @Environment(DocumentStore.self) var store: DocumentStore

    @State private var showMarkerSheet = false
    @State private var selectedMarkerType: NavigationMarkerType?
    @State private var zoomScale: CGFloat = 1.0

    let selectedImageIndex: Int

    init(document: SheetMusicDocument, selectedImageIndex: Int = 0) {
        self._document = Bindable(wrappedValue: document)
        self.selectedImageIndex = selectedImageIndex
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if !document.imagePaths.isEmpty, selectedImageIndex < document.imagePaths.count {
                EditorScrollView(zoomScale: $zoomScale) {
                    ZStack {
                        BoundingBoxEditorView(
                            document: document,
                            imagePath: document.imagePaths[selectedImageIndex]
                        )
                        MarkerPlacementView(
                            document: document,
                            imagePath: document.imagePaths[selectedImageIndex],
                            selectedMarkerType: $selectedMarkerType
                        )
                    }
                }
            } else if document.imagePaths.isEmpty {
                ContentUnavailableView(
                    "No Images",
                    systemImage: "photo",
                    description: Text("Add images to get started")
                )
            }

                VStack {
                Group {
                    if selectedMarkerType == nil {
                        Text("Drag to outline each row of music, then mark repeats or jumps within each box")
                    } else {
                        Text("Tap or drag within a segment to place")
                    }
                }
                .font(AppTheme.hintFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .padding(.top, 16)
                Spacer()
            }

            Button {
                showMarkerSheet = true
            } label: {
                Text("Mark Repeat or Jump")
                    .font(AppTheme.labelFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMarkerSheet) {
            MarkerTypePickerView(document: document, selectedMarkerType: $selectedMarkerType)
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
        PageEditorView(document: doc)
    }
    .environment(store)
}
