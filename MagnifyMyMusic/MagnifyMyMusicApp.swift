//
//  MagnifyMyMusicApp.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import SwiftData

@main
struct MagnifyMyMusicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SheetMusicDocument.self, Segment.self, NavigationMarker.self])
    }
}
