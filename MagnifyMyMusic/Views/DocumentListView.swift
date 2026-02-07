//
//  DocumentListView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import SwiftData

struct DocumentListView: View {
    @Query(sort: \SheetMusicDocument.createdAt, order: .reverse) 
    var documents: [SheetMusicDocument]
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    
    private let imageStore = ImageStore()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(documents) { doc in
                    NavigationLink {
                        if doc.segments.isEmpty {
                            DocumentEditorView(document: doc)
                        } else {
                            SegmentReaderView(document: doc)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(doc.name)
                                .font(.headline)
                            Text("\(doc.segments.count) segments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
            let doc = documents[index]
            try? imageStore.deleteAll(forDocumentName: doc.name)
            modelContext.delete(doc)
        }
    }
}

#Preview {
    let container = PreviewHelper.createPreviewContainer()
    let _ = PreviewHelper.createSampleDocument(in: container)
    
    return DocumentListView()
        .modelContainer(container)
}

