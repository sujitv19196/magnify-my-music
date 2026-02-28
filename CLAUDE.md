# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build (simulator):**
```
xcodebuild -project MagnifyMyMusic.xcodeproj -scheme MagnifyMyMusic -sdk iphonesimulator build
```

**Run all tests:**
```
xcodebuild -project MagnifyMyMusic.xcodeproj -scheme MagnifyMyMusic -sdk iphonesimulator test
```

**Run a single test:**
```
xcodebuild -project MagnifyMyMusic.xcodeproj -scheme MagnifyMyMusic -sdk iphonesimulator test \
  -only-testing:MagnifyMyMusicTests/NavigationGraphWalkerTests/testDaCapo_alFine
```

## Architecture

MagnifyMyMusic is an iOS SwiftUI app that lets musicians photograph sheet music, draw bounding boxes around staff systems (segments), annotate them with musical navigation markers, and play them back in correct musical order with pan/zoom.

### Data model

- **`SheetMusicDocument`** — top-level document. Owns `[String] imagePaths` (filenames of page images in order) and `[Segment] segments`.
- **`Segment`** — a rectangular crop of one page image. Bounding box is stored as four `Double` fields (not a `CGRect`) normalized 0–1 relative to the source image dimensions. Owns `[NavigationMarker]`. Optionally stores a `PKDrawing` as `drawingData: Data?`.
- **`NavigationMarker`** — a musical notation symbol pinned to a horizontal position within a segment (normalized 0–1 `xPosition`). Type is `NavigationMarkerType`, a rich enum covering repeats, volta endings, segno, coda, D.C., D.S., To Coda, and Fine.

### Persistence (`DocumentStore`)

Documents are stored as `.magnify` bundles under `Documents/MagnifyDocuments/<uuid>.magnify/`:
```
<uuid>.magnify/
  manifest.json      ← lightweight metadata for the list view
  document.json      ← full document tree (segments + markers)
  images/
    <uuid>.jpg       ← page images saved at JPEG 90% quality
```
`DocumentStore` is `@Observable` and injected app-wide via `.environment(documentStore)`.

### Playback algorithm (`NavigationGraphWalker`)

`NavigationGraphWalker.buildPlaybackSequence(from: document.sortedSegments)` is the core logic. It takes segments pre-sorted by (page index, Y, X) and walks a flattened `MarkerStream` to produce `[PlaybackStep]`. Each `PlaybackStep` holds a `segment` plus `startX`/`endX` (normalized within the segment), enabling partial rendering when a marker falls mid-segment (e.g., the first pass of a repeat ending at a `:||` marker partway through the last segment). The walker handles:
- Simple repeats (`||:` / `:||`)
- Volta endings (1st/2nd/shared brackets)
- D.C. / D.S. (repeats and volta are skipped after a jump, controlled by `isReplayingAfterJump`)
- To Coda / Fine

All tests for this algorithm are in `MagnifyMyMusicTests/NavigationGraphWalkerTests.swift` using XCTest.

### Navigation flow

```
DocumentListView
  └── PageSelectView          (grid of page thumbnail images)
        ├── PageEditorView    (draw/delete bounding boxes; "Add Repeat or Jump" button)
        │     └── BoundingBoxEditorView  (drag to create segments; shows MarkerTypePickerView sheet)
        └── SegmentReaderView (playback; horizontal scroll through PlaybackSteps; Apple Pencil annotation)
```

### Observable pattern

- Models (`SheetMusicDocument`, `Segment`, `NavigationMarker`, `DocumentStore`) use Swift `@Observable`.
- `ReadingSession` (playback ViewModel) also uses `@Observable`. In `SegmentReaderView` it is owned via `@State` (not `@StateObject`).
- Views use `@Bindable` to two-way bind to `@Observable` models.

### UIKit bridges

- **`ZoomableScrollView`** — wraps `UIScrollView` to give SwiftUI pinch-to-zoom + horizontal scroll for the reader.
- **`PencilKitCanvas`** — wraps `PKCanvasView` with `drawingPolicy = .pencilOnly` so touch scrolls the reader while Apple Pencil draws annotations.

### Previews

`PreviewHelper` (compiled only in `#if DEBUG`) creates a fixed-UUID document and writes placeholder JPEG images from `TestSheetMusic1`/`TestSheetMusic2` asset catalog entries. All view previews use `PreviewHelper.createPreviewStore()` and `PreviewHelper.createSampleDocument()`.
