//
//  ReadingSession.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit
internal import Combine

@MainActor
class ReadingSession: ObservableObject {
    @Published var document: SheetMusicDocument
    
    // Drawing tool state
    @Published var currentTool: PKInkingTool
    
    // Reading/playback state
    @Published var currentSegmentIndex: Int = 0
    @Published var horizontalScrollOffset: CGFloat = 0.0
    @Published private(set) var playbackSequence: [PlaybackStep] = []
    
    // User preferences stored in UserDefaults
    var pedalScrollDistance: CGFloat {
        get { UserDefaults.standard.object(forKey: "pedalScrollDistance") as? CGFloat ?? 200 }
        set { UserDefaults.standard.set(newValue, forKey: "pedalScrollDistance") }
    }
    
    init(document: SheetMusicDocument) {
        self.document = document
        self.currentTool = PKInkingTool(.pen, color: .red, width: 2)
    }
    
    func advanceByPedal() {
        horizontalScrollOffset += pedalScrollDistance
    }
    
    func buildPlaybackSequence() {
        playbackSequence = NavigationGraphWalker.buildPlaybackSequence(
            from: document.segments
        )
    }
}

