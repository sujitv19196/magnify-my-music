//
//  NavigationGraphWalkerTests.swift
//  MagnifyMyMusicTests
//
//  Created by Sujit Varadhan on 2/14/26.
//

import XCTest
@testable import MagnifyMyMusic

final class NavigationGraphWalkerTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a test segment with a label and optional navigation markers.
    private func seg(_ label: String, markers: [(NavigationMarkerType, Double)] = []) -> Segment {
        let s = Segment(imagePath: "test", boundingBox: .zero)
        s.label = label
        s.markers = markers.map { NavigationMarker(type: $0.0, xPosition: $0.1) }
        return s
    }

    /// Extracts the label sequence from playback steps for easy assertion.
    private func labels(_ steps: [PlaybackStep]) -> [String] {
        steps.map { $0.segment.label ?? "?" }
    }

    // MARK: - Basic / Linear

    /// No segments at all.
    /// Layout: (empty)
    func testEmptySegments_returnsEmptyArray() {
        let result = NavigationGraphWalker.buildPlaybackSequence(from: [])
        XCTAssertTrue(result.isEmpty)
    }

    /// Single segment, no markers.
    /// Layout: [A]
    func testSingleSegment_noMarkers() {
        let result = NavigationGraphWalker.buildPlaybackSequence(from: [seg("A")])
        XCTAssertEqual(labels(result), ["A"])
    }

    /// Two segments, no markers — simple linear traversal.
    /// Layout: [A, B]
    func testTwoSegments_noMarkers_linearTraversal() {
        let result = NavigationGraphWalker.buildPlaybackSequence(from: [seg("A"), seg("B")])
        XCTAssertEqual(labels(result), ["A", "B"])
    }

    /// Many segments, no markers.
    /// Layout: [A, B, C, D]
    func testManySegments_noMarkers_linearTraversal() {
        let result = NavigationGraphWalker.buildPlaybackSequence(from: [
            seg("A"), seg("B"), seg("C"), seg("D")
        ])
        XCTAssertEqual(labels(result), ["A", "B", "C", "D"])
    }

    // MARK: - Simple Repeats

    /// Repeat the entire piece once (play twice total).
    /// Layout: [A |:, B, C :|]
    func testSimpleRepeat_entireSection() {
        let segments = [
            seg("A", markers: [(.repeatForward, 0.0)]),
            seg("B"),
            seg("C", markers: [(.repeatBackward(times: 1), 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "A", "B", "C"])
    }

    /// Repeat starts mid-stream — content before |: is not repeated.
    /// Layout: [A, B |:, C, D :|]
    func testRepeat_forwardMarkerMidStream() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.repeatForward, 0.0)]),
            seg("C"),
            seg("D", markers: [(.repeatBackward(times: 1), 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "B", "C", "D"])
    }

    // MARK: - Volta (1st / 2nd Endings)

    /// First and second endings — no segments skipped.
    /// Layout: [A |:, B, C volta[1], D, E volta[2], F, G endVolta]
    ///
    /// Pass 1: A, B, C, D  (play volta 1 bracket: C, D)
    /// Pass 2: A, B, E, F, G (skip volta 1, play volta 2 bracket: E, F, G)
    func testVolta_firstSecondEnding() {
        let segments = [
            seg("A", markers: [(.repeatForward, 0.0)]),
            seg("B"),
            seg("C", markers: [(.volta(numbers: [1]), 0.0)]),
            seg("D"),
            seg("E", markers: [(.volta(numbers: [2]), 0.0)]),
            seg("F"),
            seg("G", markers: [(.finalVoltaEnd, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "A", "B", "E", "F", "G"])
    }

    /// Volta with shared bracket — volta [1,2] then volta [3].
    /// Layout: [A |:, B volta[1,2], C, D volta[3], E endVolta]
    ///
    /// Pass 1: A, B, C  (volta [1,2])
    /// Pass 2: A, B, C  (volta [1,2] again)
    /// Pass 3: A, D, E  (volta [3])
    func testVolta_sharedBracket() {
        let segments = [
            seg("A", markers: [(.repeatForward, 0.0)]),
            seg("B", markers: [(.volta(numbers: [1, 2]), 0.0)]),
            seg("C"),
            seg("D", markers: [(.volta(numbers: [3]), 0.0)]),
            seg("E", markers: [(.finalVoltaEnd, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "A", "B", "C", "A", "D", "E"])
    }

    // MARK: - Da Capo (D.C.)

    /// D.C. — jump to beginning and replay entire piece.
    /// Layout: [A, B, C D.C.]
    func testDaCapo_replaysFromBeginning() {
        let segments = [
            seg("A"),
            seg("B"),
            seg("C", markers: [(.dacapo, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "A", "B", "C"])
    }

    /// D.C. al Fine — replay from beginning, stop at Fine.
    /// Layout: [A, B Fine, C, D D.C.]
    ///
    /// First pass:  A, B, C, D  (Fine ignored)
    /// After D.C.:  A, B        (stops at Fine)
    func testDaCapo_alFine() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.fine, 1.0)]),
            seg("C"),
            seg("D", markers: [(.dacapo, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "A", "B"])
    }

    /// Fine is ignored on first pass — plays through to end.
    /// Layout: [A, B Fine, C]
    func testFine_ignoredOnFirstPass() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.fine, 1.0)]),
            seg("C")
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C"])
    }

    // MARK: - Dal Segno (D.S.)

    /// D.S. — jump back to segno and replay from there.
    /// Layout: [A, B Segno, C, D, E D.S.]
    ///
    /// First pass:  A, B, C, D, E
    /// After D.S.:  B, C, D, E  (from segno to end)
    func testDalSegno_replaysFromSegno() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.segno(), 0.0)]),
            seg("C"),
            seg("D"),
            seg("E", markers: [(.dalsegno(), 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "E", "B", "C", "D", "E"])
    }

    /// D.S. al Fine — jump to segno, stop at Fine.
    /// Layout: [A, B Segno, C, D Fine, E, F D.S.]
    ///
    /// First pass:  A, B, C, D, E, F  (Fine ignored)
    /// After D.S.:  B, C, D           (stops at Fine)
    func testDalSegno_alFine() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.segno(), 0.0)]),
            seg("C"),
            seg("D", markers: [(.fine, 1.0)]),
            seg("E"),
            seg("F", markers: [(.dalsegno(), 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "E", "F", "B", "C", "D"])
    }

    /// D.S. al Coda — jump to segno, then on replay take the coda jump.
    /// Layout: [A, B Segno, C ToCoda, D, E Coda, F]
    ///
    /// First pass:  A, B, C, D     (ToCoda ignored, Coda is just a landmark)
    /// After D.S.:  B, C → jump to Coda → E, F
    func testDalSegno_alCoda() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.segno(), 0.0)]),
            seg("C", markers: [(.tocoda(), 1.0)]),
            seg("D"),
            seg("E", markers: [(.coda(), 0.0)]),
            seg("F", markers: [(.dalsegno(), 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "E", "F", "B", "C", "E", "F"])
    }

    // MARK: - Repeats Skipped After Jump

    /// After D.C., repeat markers are skipped (isReplayingAfterJump = true).
    /// Layout: [A |:, B, C :|, D, E D.C.]
    ///
    /// First pass:  A, B, C, B, C, D, E  (repeat honored)
    /// After D.C.:  A, B, C, D, E        (repeat skipped)
    func testRepeatsSkipped_afterDaCapo() {
        let segments = [
            seg("A", markers: [(.repeatForward, 0.0)]),
            seg("B"),
            seg("C", markers: [(.repeatBackward(times: 1), 1.0)]),
            seg("D"),
            seg("E", markers: [(.dacapo, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "A", "B", "C", "D", "E", "A", "B", "C", "D", "E"])
    }

    /// After D.S., repeat markers are skipped.
    /// Layout: [A Segno, B |:, C, D :|, E D.S.]
    ///
    /// First pass:  A, B, C, D, C, D, E  (repeat honored)
    /// After D.S.:  A, B, C, D, E        (repeat skipped)
    func testRepeatsSkipped_afterDalSegno() {
        let segments = [
            seg("A", markers: [(.segno(), 0.0)]),
            seg("B", markers: [(.repeatForward, 0.0)]),
            seg("C"),
            seg("D", markers: [(.repeatBackward(times: 1), 1.0)]),
            seg("E", markers: [(.dalsegno(), 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "B", "C", "D", "E", "A", "B", "C", "D", "E"])
    }

    /// Volta endings are skipped after a D.C. jump.
    /// Layout: [A |:, B volta[1], C volta[2], D endVolta, E D.C.]
    ///
    /// First pass:  A, B, A, C, D, E  (volta honored)
    /// After D.C.:  A, B, C, D, E     (volta skipped — all brackets play through)
    func testVoltaSkipped_afterDaCapo() {
        let segments = [
            seg("A", markers: [(.repeatForward, 0.0)]),
            seg("B", markers: [(.volta(numbers: [1]), 0.0)]),
            seg("C", markers: [(.volta(numbers: [2]), 0.0)]),
            seg("D", markers: [(.finalVoltaEnd, 1.0)]),
            seg("E", markers: [(.dacapo, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "A", "C", "D", "E", "A", "B", "C", "D", "E"])
    }

    // MARK: - D.C. al Coda

    /// D.C. al Coda — replay from beginning, take coda on replay.
    /// Layout: [A, B ToCoda, C, D Coda, E, F D.C.]
    ///
    /// First pass:  A, B, C, D, E, F  (ToCoda ignored)
    /// After D.C.:  A, B → jump to Coda → D, E, F
    func testDaCapo_alCoda() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.tocoda(), 1.0)]),
            seg("C"),
            seg("D", markers: [(.coda(), 0.0)]),
            seg("E"),
            seg("F", markers: [(.dacapo, 1.0)])
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "E", "F", "A", "B", "D", "E", "F"])
    }

    /// D.C. al Coda — coda is in a new segment never played on first pass.
    /// Layout: [A, B ToCoda, C, D D.C., E Coda, F]
    ///
    /// First pass:  A, B, C, D       (ToCoda ignored; E, F never played)
    /// After D.C.:  A, B → jump to Coda → E, F
    func testDaCapo_alCoda_codaInNewSegment() {
        let segments = [
            seg("A"),
            seg("B", markers: [(.tocoda(), 1.0)]),
            seg("C"),
            seg("D", markers: [(.dacapo, 1.0)]),
            seg("E", markers: [(.coda(), 0.0)]),
            seg("F")
        ]
        let result = NavigationGraphWalker.buildPlaybackSequence(from: segments)
        XCTAssertEqual(labels(result), ["A", "B", "C", "D", "A", "B", "E", "F"])
    }
}
