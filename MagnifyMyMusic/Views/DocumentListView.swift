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
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(store.documentList) { manifest in
                    NavigationLink(value: manifest.id) {
                        Text(manifest.name)
                            .font(AppTheme.bodyFont)
                    }
                }
                .onDelete(perform: deleteDocuments)
            }
            .padding(.top, 8)
            .navigationTitle("Magnify My Music")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                DocumentLoaderView(documentId: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Text("New Document")
                            .font(AppTheme.labelFont)
                    }
                    .accessibilityLabel("Create new document")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                ModifyDocumentView()
            }
        }
        .environment(\.dismissToRoot) { path = NavigationPath() }
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
                PageSelectView(document: document)
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
        .navigationBarBackButtonHidden(true)
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
