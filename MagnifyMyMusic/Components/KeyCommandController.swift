//
//  KeyCommandController.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 3/14/26.
//

import SwiftUI
import UIKit

struct KeyCommandOverlay: UIViewControllerRepresentable {
    var onAdvance: () -> Void
    var onRetreat: () -> Void

    func makeUIViewController(context: Context) -> KeyCommandViewController {
        let vc = KeyCommandViewController()
        vc.onAdvance = onAdvance
        vc.onRetreat = onRetreat
        return vc
    }

    func updateUIViewController(_ vc: KeyCommandViewController, context: Context) {
        vc.onAdvance = onAdvance
        vc.onRetreat = onRetreat
    }
}

class KeyCommandViewController: UIViewController {
    var onAdvance: (() -> Void)?
    var onRetreat: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appDidBecomeActive() {
        becomeFirstResponder()
    }

    override var keyCommands: [UIKeyCommand]? {
        let advanceInputs = [
            UIKeyCommand.inputDownArrow,
            UIKeyCommand.inputRightArrow,
            UIKeyCommand.inputPageDown,
        ]
        let retreatInputs = [
            UIKeyCommand.inputUpArrow,
            UIKeyCommand.inputLeftArrow,
            UIKeyCommand.inputPageUp,
        ]

        var commands: [UIKeyCommand] = []
        for input in advanceInputs {
            let cmd = UIKeyCommand(input: input, modifierFlags: [], action: #selector(handleAdvance))
            cmd.wantsPriorityOverSystemBehavior = true
            commands.append(cmd)
        }
        for input in retreatInputs {
            let cmd = UIKeyCommand(input: input, modifierFlags: [], action: #selector(handleRetreat))
            cmd.wantsPriorityOverSystemBehavior = true
            commands.append(cmd)
        }
        return commands
    }

    @objc private func handleAdvance() {
        onAdvance?()
    }

    @objc private func handleRetreat() {
        onRetreat?()
    }
}
