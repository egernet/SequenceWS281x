//
//  Color.swift
//
//  Created by Christian Skaarup Enevoldsen on 02/12/2023.
//

import Foundation
import rpi_ws281x_swift

extension Color {
    static func * (lhs: Color, rhs: Float) -> Color {
        guard rhs > 0 else {
            return .black
        }

        guard rhs <= 1 else {
            return lhs
        }

        return .init(
            red: UInt8(Float(lhs.red) * rhs),
            green: UInt8(Float(lhs.green) * rhs),
            blue: UInt8(Float(lhs.blue) * rhs),
            white: UInt8(Float(lhs.white) * rhs)
        )
    }
}
