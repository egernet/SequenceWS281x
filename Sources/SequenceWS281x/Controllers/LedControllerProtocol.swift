//
//  LedControllerProtocol.swift
//
//  Created by Christian Skaarup Enevoldsen on 06/10/2023.
//

import Foundation

protocol LedControllerProtocol {
    var numberOfLeds: Int { get }
    var matrixWidth: Int { get }
    var sequences: [SequenceType] { get }

    func start()
    func runSequence()
}
