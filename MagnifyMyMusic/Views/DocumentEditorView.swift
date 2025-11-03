//
//  DocumentEditorView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import SwiftData

struct DocumentEditorView: View {
    @Bindable var document: SheetMusicDocument
    @State private var selectedImageIndex = 0
    
    private let imageStore = ImageStore()
    
    var body: some View {
        VStack {
            if !document.imagePaths.isEmpty {
                Picker("Image", selection: $selectedImageIndex) {
                    ForEach(0..<document.imagePaths.count, id: \.self) { index in
                        Text("Page \(index + 1)")
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedImageIndex < document.imagePaths.count {
                    BoundingBoxEditorView(
                        document: document,
                        imagePath: document.imagePaths[selectedImageIndex]
                    )
                }
            } else {
                ContentUnavailableView(
                    "No Images",
                    systemImage: "photo",
                    description: Text("Add images to get started")
                )
            }
        }
        .navigationTitle(document.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    FrameReaderView(document: document)
                } label: {
                    Label("Read", systemImage: "book")
                }
                .disabled(document.frames.isEmpty)
            }
        }
    }
}

#Preview {
    let container = PreviewHelper.createPreviewContainer()
    let document = PreviewHelper.createSampleDocument(in: container)
    
    return NavigationStack {
        DocumentEditorView(document: document)
    }
    .modelContainer(container)
}

