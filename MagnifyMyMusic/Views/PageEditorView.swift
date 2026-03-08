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
    @State private var committedBox: CGRect? = nil

    let selectedImageIndex: Int

    init(document: SheetMusicDocument, selectedImageIndex: Int = 0) {
        self._document = Bindable(wrappedValue: document)
        self.selectedImageIndex = selectedImageIndex
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if !document.imagePaths.isEmpty, selectedImageIndex < document.imagePaths.count {
                EditorScrollView(onCommit: { committedBox = $0 }) {
                    ZStack {
                        BoundingBoxEditorView(
                            document: document,
                            imagePath: document.imagePaths[selectedImageIndex],
                            committedBox: $committedBox
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
