//
//  SequenceType.swift
//
//  Created by Christian Skaarup Enevoldsen on 08/01/2023.
//

import Foundation
import rpi_ws281x_swift

protocol SequenceDelegate: AnyObject {
    func sequenceUpdatePixels(_ sequence: SequenceType)
    func sequenceSetPixelColor(_ sequence: SequenceType, point: Point, color: Color)
    func sequenceSetPixelColor(_ sequence: SequenceType, pos: Int, color: Color)
}

protocol SequenceType {
    var delegate: SequenceDelegate? {get set}
    var matrixWidth: Int {get}
    var matrixHeight: Int {get}
    var name: String { get }

    func runSequence()
}

extension SequenceType {
    var name: String {
        String(describing: self)
    }
}
