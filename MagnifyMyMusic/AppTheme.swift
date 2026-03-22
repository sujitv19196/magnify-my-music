//
//  AppTheme.swift
//  MagnifyMyMusic
//

import SwiftUI

// MARK: - Environment: dismiss to library root

private struct DismissToRootKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissToRoot: () -> Void {
        get { self[DismissToRootKey.self] }
        set { self[DismissToRootKey.self] = newValue }
    }
}

// MARK: - Design tokens

enum AppTheme {
    static let accent1 = Color(uiColor: .systemOrange)  // bounding boxes
    static let accent2 = Color(uiColor: .systemTeal)    // markers

    static let displayFont = Font.title2.weight(.bold)
    static let bodyFont    = Font.body.weight(.semibold)
    static let labelFont   = Font.body.weight(.bold)
    static let hintFont    = Font.callout.weight(.semibold)
    static let captionFont = Font.callout.weight(.semibold)

    static var screenScale: CGFloat { UIScreen.main.scale }
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }

    static var thumbnailMaxPixelSize: CGFloat { (screenWidth / 2) * screenScale }
    static var reorderMaxPixelSize: CGFloat { 80 * screenScale }

    static let defaultDrawingWidth: CGFloat = 40
    static let defaultDrawingColor: UIColor = .purple
    static let defaultZoomScale: CGFloat = 0.5
    static let defaultPedalScrollDistance: CGFloat = 200

    // MARK: - UserDefaults keys
    static let showHintsKey = "showHints"
    static let pedalScrollDistanceKey = "pedalScrollDistance"
    static let zoomScaleKey = "zoomScale"
    static let drawingToolWidthKey = "drawingToolWidth"
    static let drawingToolColorKey = "drawingToolColor"

    static func pedalScrollDistanceKey(for documentId: UUID) -> String { "\(pedalScrollDistanceKey)-\(documentId)" }
    static func zoomScaleKey(for documentId: UUID) -> String { "\(zoomScaleKey)-\(documentId)" }

    static let markerBarWidth: CGFloat = 10
    static let boundingBoxStrokeWidth: CGFloat = 2
    static let boundingBoxDraftStrokeWidth: CGFloat = 3
}
