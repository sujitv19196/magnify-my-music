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
    @State private var documentToDelete: DocumentManifest? = nil
    @State private var showingSettings = false
    @State private var showHints: Bool = UserDefaults.standard.object(forKey: AppTheme.showHintsKey) as? Bool ?? true

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(store.documentList) { manifest in
                    NavigationLink(value: manifest.id) {
                        Text(manifest.name)
                            .font(AppTheme.bodyFont)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            documentToDelete = manifest
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.top, 8)
            .navigationTitle("Magnify My Music")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                DocumentLoaderView(documentId: id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create new document")
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    Form {
                        Toggle("Show Hints", isOn: $showHints)
                            .font(AppTheme.bodyFont)
                            .onChange(of: showHints) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: AppTheme.showHintsKey)
                            }
                    }
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingSettings = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingCreateSheet) {
                ModifyDocumentView(onCreated: { createdId in
                    path.append(createdId)
                })
            }
            .alert(item: $documentToDelete) { manifest in
                Alert(
                    title: Text("Delete \"\(manifest.name)\"?"),
                    message: Text("This cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        try? store.delete(id: manifest.id)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .environment(\.dismissToRoot) { path = NavigationPath() }
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
