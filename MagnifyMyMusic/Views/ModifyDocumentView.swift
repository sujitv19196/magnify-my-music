//
//  ModifyDocumentView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/28/26.
//

import SwiftUI
import PhotosUI
import VisionKit

struct ModifyDocumentView: View {
    @Environment(DocumentStore.self) var store
    @Environment(\.dismiss) private var dismiss

    var document: SheetMusicDocument? = nil

    @State private var documentName = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingScanner = false

    private var isCreateMode: Bool { document == nil }

    init(document: SheetMusicDocument? = nil) {
        self.document = document
        _documentName = State(initialValue: document?.name ?? "")
    }

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
                        Label("Select from Library", systemImage: "photo.on.rectangle")
                    }

                    if VNDocumentCameraViewController.isSupported {
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan Document", systemImage: "doc.viewfinder")
                        }
                    }

                    if !selectedImages.isEmpty {
                        Text("\(selectedImages.count) image\(selectedImages.count == 1 ? "" : "s") selected")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(isCreateMode ? "New Document" : "Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreateMode ? "Create" : "Save") {
                        saveDocument()
                    }
                    .disabled(isCreateMode ? (documentName.isEmpty || selectedImages.isEmpty) : documentName.isEmpty)
                }
            }
            .onChange(of: selectedItems) { _, newValue in
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
            .fullScreenCover(isPresented: $showingScanner) {
                DocumentScannerView { images in
                    selectedImages.append(contentsOf: images)
                    showingScanner = false
                } onCancel: {
                    showingScanner = false
                }
                .ignoresSafeArea()
            }
        }
    }

    private func saveDocument() {
        if let doc = document {
            // Edit mode: append new images and update name
            doc.name = documentName
            let newPaths = selectedImages.compactMap { image in
                try? store.saveImage(image, to: doc.id)
            }
            doc.imagePaths.append(contentsOf: newPaths)
            try? store.save(doc)
        } else {
            // Create mode: create a new document
            let doc = SheetMusicDocument(name: documentName)
            try? store.save(doc)
            doc.imagePaths = selectedImages.compactMap { image in
                try? store.saveImage(image, to: doc.id)
            }
            try? store.save(doc)
        }
        dismiss()
    }
}
