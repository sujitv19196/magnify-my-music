//
//  ReadingSession.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit

@Observable
class ReadingSession {
    var document: SheetMusicDocument

    // Drawing tool state
    var currentTool: PKTool {
        didSet { saveToolPreferences() }
    }
    var fingerDrawingEnabled: Bool = false

    // Reading/playback state
    var currentSegmentIndex: Int = 0
    private(set) var playbackSequence: [PlaybackStep] = []

    // User preferences stored in UserDefaults
    var pedalScrollDistance: CGFloat {
        didSet { UserDefaults.standard.set(pedalScrollDistance, forKey: AppTheme.pedalScrollDistanceKey(for: document.id)) }
    }

    var zoomScale: CGFloat {
        get { UserDefaults.standard.object(forKey: AppTheme.zoomScaleKey(for: document.id)) as? CGFloat ?? AppTheme.defaultZoomScale }
        set { UserDefaults.standard.set(newValue, forKey: AppTheme.zoomScaleKey(for: document.id)) }
    }

    init(document: SheetMusicDocument) {
        self.document = document

        let savedWidth = UserDefaults.standard.object(forKey: AppTheme.drawingToolWidthKey) as? CGFloat ?? AppTheme.defaultDrawingWidth
        let savedColor = Self.loadColor() ?? AppTheme.defaultDrawingColor
        self.currentTool = PKInkingTool(.pen, color: savedColor, width: savedWidth)

        self.pedalScrollDistance = UserDefaults.standard.object(forKey: AppTheme.pedalScrollDistanceKey(for: document.id)) as? CGFloat ?? AppTheme.defaultPedalScrollDistance
    }

    func advanceByPedal() {
        NotificationCenter.default.post(
            name: .pedalScroll,
            object: nil,
            userInfo: ["delta": pedalScrollDistance]
        )
    }

    func retreatByPedal() {
        NotificationCenter.default.post(
            name: .pedalScroll,
            object: nil,
            userInfo: ["delta": -pedalScrollDistance]
        )
    }

    func buildPlaybackSequence() {
        playbackSequence = NavigationGraphWalker.buildPlaybackSequence(
            // Sorts by page number, then top-to-bottom, then left-to-right
            from: document.sortedSegments
        )
    }

    private func saveToolPreferences() {
        guard let inkingTool = currentTool as? PKInkingTool else { return }
        UserDefaults.standard.set(inkingTool.width, forKey: AppTheme.drawingToolWidthKey)
        Self.saveColor(inkingTool.color)
    }

    private static func saveColor(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        UserDefaults.standard.set([r, g, b, a], forKey: AppTheme.drawingToolColorKey)
    }

    private static func loadColor() -> UIColor? {
        guard let components = UserDefaults.standard.array(forKey: AppTheme.drawingToolColorKey) as? [CGFloat],
              components.count == 4 else { return nil }
        return UIColor(red: components[0], green: components[1],
                       blue: components[2], alpha: components[3])
    }
}
