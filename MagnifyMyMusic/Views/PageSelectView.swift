//
//  PageSelectView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/15/26.
//

import SwiftUI

struct PageSelectView: View {
    @Bindable var document: SheetMusicDocument
    @Environment(DocumentStore.self) var store: DocumentStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(document.imagePaths.enumerated()), id: \.offset) { index, path in
                    NavigationLink {
                        PageEditorView(document: document, selectedImageIndex: index)
                    } label: {
                        VStack {
                            if let image = try? store.loadImage(path, from: document.id) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .aspectRatio(0.75, contentMode: .fit)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                    }
                            }
                            Text("Page \(index + 1)")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            ModifyDocumentView(document: document)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Library", systemImage: "books.vertical")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
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
    }
}

#Preview {
    let store = PreviewHelper.createPreviewStore()
    let doc = PreviewHelper.createSampleDocument()

    NavigationStack {
        PageSelectView(document: doc)
    }
    .environment(store)
}
