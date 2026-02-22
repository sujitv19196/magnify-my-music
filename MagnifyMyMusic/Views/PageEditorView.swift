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

    let selectedImageIndex: Int

    init(document: SheetMusicDocument, selectedImageIndex: Int = 0) {
        self._document = Bindable(wrappedValue: document)
        self.selectedImageIndex = selectedImageIndex
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                if !document.imagePaths.isEmpty, selectedImageIndex < document.imagePaths.count {
                    BoundingBoxEditorView(
                        document: document,
                        imagePath: document.imagePaths[selectedImageIndex]
                    )
                } else if document.imagePaths.isEmpty {
                    ContentUnavailableView(
                        "No Images",
                        systemImage: "photo",
                        description: Text("Add images to get started")
                    )
                }
            }

            Button {
                showMarkerSheet = true
            } label: {
                Text("Add Repeat or Jump")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    SegmentReaderView(document: document)
                } label: {
                    Label("Read", systemImage: "book")
                }
                .disabled(document.segments.isEmpty)
            }
        }
        .sheet(isPresented: $showMarkerSheet) {
            MarkerSelectionView(document: document, selectedMarkerType: $selectedMarkerType)
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
