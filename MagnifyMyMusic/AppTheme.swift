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

    static let markerBarWidth: CGFloat = 10
    static let boundingBoxStrokeWidth: CGFloat = 2
    static let boundingBoxDraftStrokeWidth: CGFloat = 3
}
