//
//  PageReorderView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/15/26.
//

import SwiftUI

struct PageItem: Identifiable {
    let id = UUID()
    let path: String
}

struct PageReorderView: View {
    @Binding var items: [PageItem]
    let store: DocumentStore
    let documentId: UUID
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var editMode = EditMode.active
    @State private var images: [String: UIImage] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    HStack {
                        if let image = images[item.path] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        Text("Page \((items.firstIndex(where: { $0.id == item.id }) ?? 0) + 1)")
                            .font(AppTheme.labelFont)
                    }
                }
                .onMove { from, to in
                    items.move(fromOffsets: from, toOffset: to)
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Reorder Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
        .onAppear {
            for item in items {
                images[item.path] = try? store.loadImage(item.path, from: documentId)
            }
        }
    }
}
