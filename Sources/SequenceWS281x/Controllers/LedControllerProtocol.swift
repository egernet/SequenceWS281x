//
//  LedControllerProtocol.swift
//
//  Created by Christian Skaarup Enevoldsen on 06/10/2023.
//

import Foundation

protocol LedControllerProtocol {
    /// Get the width of  the matrix
    var matrixWidth: Int { get }
    
    /// Get the height of  the matrix
    var matrixHeight: Int { get }
    
    /// Get list of sequence
    var sequences: [SequenceType] { get }

    /// Start up the controller
    func start()
    
    /// Begin run the sequences
    func runSequence()
}
