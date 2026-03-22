//
//  PageEditorView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

enum EditorSelection: Equatable {
    case segment(UUID)
    case marker(UUID)
    case none

    var isSegment: Bool {
        if case .segment = self { return true }
        return false
    }
}

struct PageEditorView: View {
    @Bindable var document: SheetMusicDocument
    @Environment(DocumentStore.self) var store: DocumentStore

    @State private var showMarkerSheet = false
    @State private var selectedMarkerType: NavigationMarkerType?
    @State private var committedBox: CGRect? = nil
    @State private var editorSelection: EditorSelection = .none
    @State private var isDrawingBox = false
    @State private var showHints: Bool = UserDefaults.standard.object(forKey: AppTheme.showHintsKey) as? Bool ?? true

    let selectedImageIndex: Int

    init(document: SheetMusicDocument, selectedImageIndex: Int = 0) {
        self._document = Bindable(wrappedValue: document)
        self.selectedImageIndex = selectedImageIndex
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if !document.imagePaths.isEmpty, selectedImageIndex < document.imagePaths.count {
                EditorScrollView(onCommit: { committedBox = $0 }, onDragStateChanged: { isDrawingBox = $0 }) {
                    ZStack {
                        BoundingBoxEditorView(
                            document: document,
                            imagePath: document.imagePaths[selectedImageIndex],
                            committedBox: $committedBox,
                            editorSelection: $editorSelection
                        )
                        MarkerPlacementView(
                            document: document,
                            imagePath: document.imagePaths[selectedImageIndex],
                            selectedMarkerType: $selectedMarkerType,
                            editorSelection: $editorSelection
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
                if showHints && !isDrawingBox && selectedMarkerType == nil && editorSelection == .none {
                    Text("Use two fingers to draw a box around each row of music. Then mark any repeats or jumps for each row.")
                        .font(AppTheme.hintFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
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
