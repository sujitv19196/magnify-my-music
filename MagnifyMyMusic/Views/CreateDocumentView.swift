//
//  CreateDocumentView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PhotosUI
import SwiftData

struct CreateDocumentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var documentName = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    private let imageStore = ImageStore()
    
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
        
        doc.imagePaths = selectedImages.enumerated().compactMap { (index, image) in
            try? imageStore.save(image, documentName: documentName, index: index)
        }
        
        modelContext.insert(doc)
        dismiss()
    }
}

