//
//  TwistSequence.swift
//
//
//  Created by Christian Skaarup Enevoldsen on 19/11/2023.
//

import Foundation
import rpi_ws281x_swift

final class TwistSequence: SequenceType {
    var delegate: SequenceDelegate?
    let matrixHeight: Int
    let matrixWidth: Int
    let color: Color

    init(matrixWidth: Int, matrixHeight: Int, color: Color = .white) {
        self.matrixHeight = matrixHeight
        self.matrixWidth = matrixWidth
        self.color = color
    }

    func runSequence() {
        switchColor()
    }

    private func switchColor() {
        var row = 0
        for point in 0..<matrixHeight {
            for width in 0..<matrixWidth {
                for i in 0..<matrixHeight {
                    delegate?.sequenceSetPixelColor(self, point: .init(x: i, y: width), color: point == i && row == width ? color : .black )
                }
            }
            
            row = row + 1

            if row == 3 {
                row = 0
            }

            delegate?.sequenceUpdatePixels(self)
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
}
