//
//  DocumentEditorView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct DocumentEditorView: View {
    @Bindable var document: SheetMusicDocument
    @State private var selectedImageIndex = 0
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
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
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(selection: $selectedPhotos, matching: .images) {
                    Label("Add Images", systemImage: "photo.on.rectangle.angled")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    SegmentReaderView(document: document)
                } label: {
                    Label("Read", systemImage: "book")
                }
                .disabled(document.segments.isEmpty)
            }
        }
        .onChange(of: selectedPhotos) { oldValue, newValue in
            Task {
                await loadImages(from: newValue)
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                continue
            }
            
            // Save image and add to document
            let currentIndex = document.imagePaths.count
            if let filename = try? imageStore.save(uiImage, documentName: document.name, index: currentIndex) {
                document.imagePaths.append(filename)
                // Switch to the newly added image
                selectedImageIndex = document.imagePaths.count - 1
            }
        }
        
        // Clear selection
        selectedPhotos = []
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

