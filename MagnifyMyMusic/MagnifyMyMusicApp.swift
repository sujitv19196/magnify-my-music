//
//  MagnifyMyMusicApp.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI

@main
struct MagnifyMyMusicApp: App {
    @State private var documentStore = DocumentStore()
    
    var body: some Scene {
        WindowGroup {
            DocumentListView()
        }
        .environment(documentStore)
    }
}
