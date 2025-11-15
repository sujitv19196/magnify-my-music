//
//  Repeat.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftData
import Foundation

@Model
class Repeat {
    @Attribute(.unique) var id: UUID
    var startFrameIndex: Int
    var endFrameIndex: Int
    var jumpToFrameIndex: Int
    var type: RepeatType
    var timesToRepeat: Int
    
    init(startFrameIndex: Int, endFrameIndex: Int, jumpToFrameIndex: Int, type: RepeatType, timesToRepeat: Int = 1) {
        self.id = UUID()
        self.startFrameIndex = startFrameIndex
        self.endFrameIndex = endFrameIndex
        self.jumpToFrameIndex = jumpToFrameIndex
        self.type = type
        self.timesToRepeat = timesToRepeat
    }
}

enum RepeatType: String, Codable {
    case simple        // ||: :||
    case volta1        // 1.___
    case volta2        // 2.___
    case daCapo        // D.C.
    case dalSegno      // D.S.
    case coda          // Coda jump
}

