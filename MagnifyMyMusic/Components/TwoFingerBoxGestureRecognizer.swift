//
//  TwoFingerBoxGestureRecognizer.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 3/8/26.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Tracks exactly two simultaneous touches and reports the bounding CGRect they span.
/// A third finger cancels the gesture. Single-finger taps pass through unaffected
/// when cancelsTouchesInView = false is set on the recognizer.
final class TwoFingerBoxGestureRecognizer: UIGestureRecognizer {

    /// Called continuously while both fingers are held down.
    var onChange: ((CGRect) -> Void)?
    /// Called once when either finger lifts (gesture completed).
    var onCommit: ((CGRect) -> Void)?
    /// Called when the gesture is cancelled (e.g. third finger, system interrupt).
    var onCancel: (() -> Void)?

    private var touch1: UITouch?
    private var touch2: UITouch?

    /// Minimum distance (pts) between the two touch points before the gesture activates.
    /// Prevents a single fat finger registering as two close points from creating a box.
    private let minimumTouchSeparation: CGFloat = 60

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            if touch1 == nil {
                touch1 = touch
            } else if touch2 == nil {
                touch2 = touch
                // Only begin if the two fingers are far enough apart
                if let v = view,
                   let p1 = touch1?.location(in: v),
                   let p2 = touch2?.location(in: v),
                   hypot(p2.x - p1.x, p2.y - p1.y) >= minimumTouchSeparation {
                    state = .began
                    reportCurrentRect()
                } else {
                    state = .failed
                    return
                }
            } else {
                // Third or more finger: abort
                state = .cancelled
                return
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard state == .began || state == .changed else { return }
        guard touches.contains(where: { $0 === touch1 || $0 === touch2 }) else { return }
        state = .changed
        reportCurrentRect()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if state == .possible {
            // Never got a second finger — fail explicitly so UIKit delivers
            // the touch-ended event to the underlying button without delay.
            state = .failed
            return
        }
        guard state == .began || state == .changed else { return }
        if let rect = currentRect() { onCommit?(rect) }
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        if state == .possible {
            state = .failed
            return
        }
        onCancel?()
        state = .cancelled
    }

    override func reset() {
        super.reset()
        touch1 = nil
        touch2 = nil
    }

    private func currentRect() -> CGRect? {
        guard let t1 = touch1, let t2 = touch2, let v = view else { return nil }
        let p1 = t1.location(in: v)
        let p2 = t2.location(in: v)
        return CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }

    private func reportCurrentRect() {
        if let rect = currentRect() { onChange?(rect) }
    }
}
