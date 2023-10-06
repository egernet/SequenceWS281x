//
//  Console.swift
//
//  Created by Christian Skaarup Enevoldsen on 08/01/2023.
//

import Foundation
import rpi_ws281x_swift

class Console {
    static func moveCursor(_ point: Point) {
        print("\u{1B}[\(point.y);\(point.x)H")
    }

    static func write(_ text: String, color: Color = .white) {
        print("\u{001B}[38;2;\(color.red);\(color.green);\(color.blue)m", terminator: "")
        print("\(text)\u{001B}[0m", terminator: "")
    }

    static func writeLine(_ text: String, color: Color = .white) {
        write(text + "\n", color: color)
    }
}
