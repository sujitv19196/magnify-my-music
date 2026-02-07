//
//  ContentView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        DocumentListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SheetMusicDocument.self, Segment.self, NavigationMarker.self], inMemory: true)
}
