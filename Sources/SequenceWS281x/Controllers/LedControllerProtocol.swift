//
//  LedControllerProtocol.swift
//
//  Created by Christian Skaarup Enevoldsen on 06/10/2023.
//

import Foundation

protocol LedControllerProtocol {
    var matrixWidth: Int { get }
    var matrixHeight: Int {get}
    var sequences: [SequenceType] { get }

    func start()
    func runSequence()
}

extension LedControllerProtocol {
    func fromPostionToPoint(_ pos: Int) -> Point {
        let y = pos / matrixHeight
        let x = pos - (y * matrixHeight)

        return .init(x: x, y: y)
    }

    func sleep(forTimeInterval: TimeInterval = 0.001) {
        Thread.sleep(forTimeInterval: forTimeInterval)
    }
}
