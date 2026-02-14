//
//  DocumentListView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

struct DocumentListView: View {
    @Environment(DocumentStore.self) var store
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.documentList) { manifest in
                    NavigationLink {
                        DocumentLoaderView(documentId: manifest.id)
                    } label: {
                        Text(manifest.name)
                            .font(.headline)
                    }
                }
                .onDelete(perform: deleteDocuments)
            }
            .navigationTitle("Magnify My Music")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("New Document", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateDocumentView()
            }
        }
    }
    
    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            let manifest = store.documentList[index]
            try? store.delete(id: manifest.id)
        }
    }
}

/// Loads the full document on appear and routes to editor or reader.
private struct DocumentLoaderView: View {
    let documentId: UUID
    @Environment(DocumentStore.self) var store
    @State private var document: SheetMusicDocument?
    @State private var loadFailed = false
    
    var body: some View {
        Group {
            if let document {
                if document.segments.isEmpty {
                    DocumentEditorView(document: document)
                } else {
                    SegmentReaderView(document: document)
                }
            } else if loadFailed {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Could not read this document.")
                )
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                document = try store.loadDocument(id: documentId)
            } catch {
                loadFailed = true
            }
        }
    }
}

#Preview {
    DocumentListView()
        .environment(PreviewHelper.createPreviewStore())
}
