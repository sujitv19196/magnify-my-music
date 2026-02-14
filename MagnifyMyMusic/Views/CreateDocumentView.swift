//
//  CreateDocumentView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PhotosUI

struct CreateDocumentView: View {
    @Environment(DocumentStore.self) var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var documentName = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Document Name") {
                    TextField("Name", text: $documentName)
                }
                
                Section("Images") {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Label("Select Images", systemImage: "photo.on.rectangle")
                    }
                    
                    if !selectedImages.isEmpty {
                        Text("\(selectedImages.count) images selected")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createDocument()
                    }
                    .disabled(documentName.isEmpty || selectedImages.isEmpty)
                }
            }
            .onChange(of: selectedItems) { oldValue, newValue in
                Task {
                    selectedImages = []
                    for item in newValue {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
    
    private func createDocument() {
        let doc = SheetMusicDocument(name: documentName)
        
        // Save the bundle first so the images/ directory exists
        try? store.save(doc)
        
        // Save images into the bundle
        doc.imagePaths = selectedImages.enumerated().compactMap { (index, image) in
            try? store.saveImage(image, to: doc.id, index: index)
        }
        
        // Save again with updated imagePaths
        try? store.save(doc)
        dismiss()
    }
}
