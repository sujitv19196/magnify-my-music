//
//  NavigationGraphWalker.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/7/26.
//
//  Walks the navigation markers on a sorted list of segments and produces an unrolled playback order.
//

import Foundation

/// A single step in the unrolled playback sequence.
struct PlaybackStep: Identifiable {
    let id: UUID = UUID()
    let segment: Segment
    /// Where within the segment's bounding box to start displaying, normalized 0.0-1.0.
    let startX: Double
    /// Where within the segment's bounding box to end displaying, normalized 0.0-1.0.
    let endX: Double
}

/// A marker with its position in the global stream.
/// Sorted by (segmentIndex, xPosition) so the walker sees them in reading order.
private struct MarkerStreamEntry {
    let segmentIndex: Int
    let marker: NavigationMarker
}

enum NavigationGraphWalker {
    static func buildPlaybackSequence(from inputSegments: [Segment]) -> [PlaybackStep] {
        let segments = inputSegments  // Caller should provide pre-sorted segments (page number, then top-to-bottom, then left-to-right)
        guard !segments.isEmpty else { return [] }

        var markerStream: [MarkerStreamEntry] = []
        for (i, segment) in segments.enumerated() {
            for marker in segment.markers.sorted(by: { $0.xPosition < $1.xPosition }) {
                markerStream.append(MarkerStreamEntry(segmentIndex: i, marker: marker))
            }
        }

        var result: [PlaybackStep] = []
        var cursor = 0                       // index into markerStream
        var repeatJumpBack: Int? = nil       // stream index of the repeatForward
        var repeatTimesLeft: Int = 0         // jumps remaining for current repeat
        var currentVoltaPass: Int = 1        // 1-based pass through volta section
        var isReplayingAfterJump: Bool = false // true after D.S. or D.C.
        var lastEmittedSegIndex: Int = -1    // track which segment we last emitted
        var lastEmittedEndX: Double = 0.0    // where we left off in that segment

        let maxIterations = markerStream.count * 20
        var iterations = 0

        walkLoop: while cursor < markerStream.count, iterations < maxIterations {
            iterations += 1

            let entry = markerStream[cursor]

            // Emit segments between last emitted position and this marker
            emitSegmentRange(
                from: lastEmittedSegIndex, startX: lastEmittedEndX,
                through: entry.segmentIndex, endX: entry.marker.xPosition,
                segments: segments, into: &result
            )
            lastEmittedSegIndex = entry.segmentIndex
            lastEmittedEndX = entry.marker.xPosition

            switch entry.marker.type {
                case .repeatForward:
                    if isReplayingAfterJump { cursor += 1; break }
                    repeatJumpBack = cursor
                    cursor += 1
                case .repeatBackward(let times):
                    if isReplayingAfterJump { cursor += 1; break }
                    if repeatTimesLeft == 0 {
                        // First time hitting this backward marker
                        repeatTimesLeft = times
                    }
                    if repeatTimesLeft > 0, let jumpBack = repeatJumpBack {
                        repeatTimesLeft -= 1
                        jumpTo(jumpBack, cursor: &cursor, lastEmitted: &lastEmittedSegIndex, lastEmittedEndX: &lastEmittedEndX, in: markerStream)
                    } else {
                        // Done repeating — clean up and move forward
                        repeatJumpBack = nil
                        repeatTimesLeft = 0
                        cursor += 1
                    }
                case .volta(let numbers):
                    if isReplayingAfterJump { cursor += 1; break }
                    if numbers.contains(currentVoltaPass) {
                        // This volta is for our current pass — play it
                        cursor += 1
                    } else {
                        // Not our pass — skip ahead to the next volta or finalVoltaEnd
                        let target = skipToNextVoltaBoundary(from: cursor, in: markerStream)
                        jumpTo(target, cursor: &cursor, lastEmitted: &lastEmittedSegIndex, lastEmittedEndX: &lastEmittedEndX, in: markerStream)
                    }
                case .finalVoltaEnd:
                    if isReplayingAfterJump { cursor += 1; break }
                    // Check if more passes are needed by finding the highest volta number
                    let totalPasses = maxVoltaPass(from: repeatJumpBack ?? 0, to: cursor, in: markerStream)
                    if currentVoltaPass < totalPasses, let jumpBack = repeatJumpBack {
                        // More passes needed — jump back to repeatForward for next pass
                        currentVoltaPass += 1
                        jumpTo(jumpBack, cursor: &cursor, lastEmitted: &lastEmittedSegIndex, lastEmittedEndX: &lastEmittedEndX, in: markerStream)
                    } else {
                        // All passes done — continue with the music
                        currentVoltaPass = 1
                        repeatJumpBack = nil
                        cursor += 1
                    }

                // Jump targets: just landmarks, advance cursor
                case .segno:
                    cursor += 1
                case .coda:
                    cursor += 1

                // Jump commands
                case .dacapo:
                    // Jump to beginning of piece, start replay
                    isReplayingAfterJump = true
                    jumpTo(0, cursor: &cursor, lastEmitted: &lastEmittedSegIndex, lastEmittedEndX: &lastEmittedEndX, in: markerStream)
                case .dalsegno(let label):
                    // Jump back to matching segno
                    if let target = findStreamIndex(in: markerStream, matching: { if case .segno(let l) = $0 { return l == label }; return false }) {
                        isReplayingAfterJump = true
                        jumpTo(target, cursor: &cursor, lastEmitted: &lastEmittedSegIndex, lastEmittedEndX: &lastEmittedEndX, in: markerStream)
                    } else {
                        cursor += 1
                    }
                case .tocoda(let label):
                    if isReplayingAfterJump {
                        // Jump forward to matching coda
                        if let target = findStreamIndex(in: markerStream, matching: { if case .coda(let l) = $0 { return l == label }; return false }) {
                            jumpTo(target, cursor: &cursor, lastEmitted: &lastEmittedSegIndex, lastEmittedEndX: &lastEmittedEndX, in: markerStream)
                        } else {
                            cursor += 1
                        }
                    } else {
                        // Not replaying — ignore tocoda
                        cursor += 1
                    }
                case .fine:
                    if isReplayingAfterJump {
                        // End of piece during replay
                        break walkLoop
                    }
                    cursor += 1
            }
        }

        // Emit any remaining segments after the last marker
        // Also emits if no markers were found
        emitSegmentRange(
            from: lastEmittedSegIndex, startX: lastEmittedEndX,
            through: segments.count - 1, endX: 1.0,
            segments: segments, into: &result
        )

        return result
    }

    /// Emits PlaybackSteps for the segment range from `(fromIndex, startX)` to `(throughIndex, endX)`.
    /// Handles partial first/last segments and full segments in between.
    private static func emitSegmentRange(
        from fromIndex: Int, startX: Double,
        through throughIndex: Int, endX: Double,
        segments: [Segment],
        into result: inout [PlaybackStep]
    ) {
        // Determine the first segment to emit
        let firstSeg: Int
        let firstStartX: Double
        if fromIndex < 0 {
            firstSeg = 0
            firstStartX = 0.0
        } else if startX >= 1.0 {
            // We finished the previous segment, start fresh on the next one
            firstSeg = fromIndex + 1
            firstStartX = 0.0
        } else {
            firstSeg = fromIndex
            firstStartX = startX
        }

        guard firstSeg <= throughIndex else { return }

        for i in firstSeg...throughIndex {
            let sX  = (i == firstSeg) ? firstStartX : 0.0
            let eX = (i == throughIndex) ? endX : 1.0

            // Don't emit zero-width slices
            if eX > sX {
                result.append(PlaybackStep(
                    segment: segments[i], startX: sX, endX: eX
                ))
            }
        }
    }

    /// Moves cursor to `target`. For forward jumps, also updates emission position to skip content.
    /// For backward jumps, emitSegmentRange's guard handles it naturally.
    private static func jumpTo(
        _ target: Int,
        cursor: inout Int,
        lastEmitted: inout Int,
        lastEmittedEndX: inout Double,
        in stream: [MarkerStreamEntry]
    ) {
        let isForward = target > cursor
        cursor = target
        if isForward, target < stream.count {
            lastEmitted = stream[target].segmentIndex
            lastEmittedEndX = stream[target].marker.xPosition
        }
    }

    /// Finds the first stream index whose marker type matches the predicate.
    private static func findStreamIndex(
        in stream: [MarkerStreamEntry],
        matching predicate: (NavigationMarkerType) -> Bool
    ) -> Int? {
        stream.firstIndex { predicate($0.marker.type) }
    }

    /// Returns the highest ending number across all `volta` markers between `from` and `to` in the stream.
    private static func maxVoltaPass(from: Int, to: Int, in stream: [MarkerStreamEntry]) -> Int {
        var maxPass = 1
        for i in from...to {
            if case .volta(let numbers) = stream[i].marker.type {
                if let m = numbers.max(), m > maxPass { maxPass = m }
            }
        }
        return maxPass
    }

    /// Advances the cursor past the current volta to the next `volta` or `finalVoltaEnd`.
    private static func skipToNextVoltaBoundary(from cursor: Int, in stream: [MarkerStreamEntry]) -> Int {
        var i = cursor + 1
        while i < stream.count {
            switch stream[i].marker.type {
                case .volta, .finalVoltaEnd:
                    return i  // return TO this index so the main loop processes it
                default:
                    i += 1
            }
        }
        return i  // past end of stream
    }
}
