//
//  PageSelectView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/15/26.
//

import SwiftUI
import UniformTypeIdentifiers

private struct PageItem: Identifiable {
    let id = UUID()
    let path: String
}

struct PageSelectView: View {
    @Bindable var document: SheetMusicDocument
    @Environment(DocumentStore.self) var store: DocumentStore
    @Environment(\.dismiss) private var dismiss
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var showingEditSheet = false
    @State private var isReordering = false
    @State private var reorderItems: [PageItem] = []
    @State private var draggingItem: PageItem?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                if isReordering {
                    reorderGrid
                } else {
                    normalGrid
                }
            }
            .padding()
        }
        .task {
            var cache: [String: UIImage] = [:]
            for path in document.imagePaths {
                if cache[path] == nil {
                    cache[path] = store.loadImage(path, from: document.id, maxPixelSize: AppTheme.thumbnailMaxPixelSize)
                }
            }
            thumbnails = cache
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            ModifyDocumentView(document: document)
        }
        .toolbar {
            if isReordering {
                reorderToolbar
            } else {
                normalToolbar
            }
        }
        .animation(.default, value: isReordering)
    }

    // MARK: - Normal Grid

    private var normalGrid: some View {
        ForEach(Array(document.imagePaths.enumerated()), id: \.offset) { index, path in
            NavigationLink {
                PageEditorView(document: document, selectedImageIndex: index)
            } label: {
                pageThumbnail(path: path, index: index)
            }
        }
    }

    // MARK: - Reorder Grid

    private var reorderGrid: some View {
        ForEach(Array(reorderItems.enumerated()), id: \.element.id) { index, item in
            pageThumbnail(path: item.path, index: index)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.accent2, lineWidth: 2)
                )
                .opacity(draggingItem?.id == item.id ? 0.5 : 1.0)
                .onDrag {
                    draggingItem = item
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
                .onDrop(of: [UTType.text], delegate: PageReorderDropDelegate(
                    item: item,
                    items: $reorderItems,
                    draggingItem: $draggingItem
                ))
        }
    }

    // MARK: - Shared Thumbnail

    private func pageThumbnail(path: String, index: Int) -> some View {
        VStack {
            if let image = thumbnails[path] {
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
                .font(AppTheme.displayFont)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var normalToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Text("Library")
                    .font(AppTheme.labelFont)
            }
            .accessibilityLabel("Return to Library")
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingEditSheet = true
            } label: {
                Text("Edit")
                    .font(AppTheme.labelFont)
            }
            .accessibilityLabel("Edit document details")
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                reorderItems = document.imagePaths.map { PageItem(path: $0) }
                isReordering = true
            } label: {
                Text("Reorder")
                    .font(AppTheme.labelFont)
            }
            .accessibilityLabel("Reorder pages")
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                SegmentReaderView(document: document)
            } label: {
                Text("Read")
                    .font(AppTheme.labelFont)
            }
            .accessibilityLabel("Start reading")
            .disabled(document.segments.isEmpty)
        }
    }

    @ToolbarContentBuilder
    private var reorderToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                isReordering = false
                reorderItems = []
                draggingItem = nil
            } label: {
                Text("Cancel")
                    .font(AppTheme.labelFont)
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                document.imagePaths = reorderItems.map { $0.path }
                try? store.save(document)
                isReordering = false
                reorderItems = []
                draggingItem = nil
            } label: {
                Text("Done")
                    .font(AppTheme.labelFont)
            }
        }
    }
}

// MARK: - Drop Delegate

private struct PageReorderDropDelegate: DropDelegate {
    let item: PageItem
    @Binding var items: [PageItem]
    @Binding var draggingItem: PageItem?

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingItem,
              dragging.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id })
        else { return }

        withAnimation {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
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
