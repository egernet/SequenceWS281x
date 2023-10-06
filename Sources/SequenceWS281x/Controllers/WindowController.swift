//
//  File.swift
//
//  Created by Christian Skaarup Enevoldsen on 05/10/2023.
//

import Foundation
import rpi_ws281x_swift

#if os(OSX)
import Cocoa
import CoreGraphics

class WindowController: LedControllerProtocol {
    let numberOfLeds: Int
    let matrixWidth: Int
    let sequences: [SequenceType]
    let ledSize: CGFloat = 30

    let window: NSWindow
    let contentView: LEDView

    var applicationDelegate: ApplicationDelegate?

    init(sequences: [SequenceType], numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
        self.sequences = sequences

        let rowNumber = numberOfLeds / matrixWidth
        let mask: NSWindow.StyleMask = [.titled, .closable]
        let rect: NSRect = .init(x: 0, y: 0, width: CGFloat(rowNumber) * ledSize, height: CGFloat(matrixWidth) * ledSize)
        self.window = NSWindow(contentRect: rect, styleMask: mask, backing: NSWindow.BackingStoreType.buffered, defer: false)
        self.window.title = "SequenceWS281x"

        self.contentView = LEDView()

        setup()
    }

    func setup() {
        window.contentView = contentView
        contentView.setup(numberOfLeds: numberOfLeds, matrixWidth: matrixWidth, size: ledSize)

        for var sequence in sequences {
            sequence.delegate = self
        }
    }

    func start() {
        window.makeKeyAndOrderFront(self)

        let application = NSApplication.shared
        application.setActivationPolicy(NSApplication.ActivationPolicy.regular)

        let applicationDelegate = ApplicationDelegate(controller: self)
        application.delegate = applicationDelegate
        application.activate(ignoringOtherApps: true)
        application.run()
    }

    func runSequence() {
        for sequence in sequences {
            sequence.runSequence()
        }
    }

    private func updatePixels() {
        DispatchQueue.main.async {
            self.contentView.setNeedsDisplay(self.contentView.frame)
        }
    }

    private func setPixelColor(point: Point, color: Color) {
        DispatchQueue.main.async {
            self.contentView.setPixelColor(point: point, color: color)
        }
    }

    private func setPixelColor(pos: Int, color: Color) {
        let count = numberOfLeds / matrixWidth
        let y = pos / count
        let x = pos - (y * count)
        setPixelColor(point: .init(x: x, y: y), color: color)
    }
}

extension WindowController: SequenceDelegate {
    func sequenceUpdatePixels(_ sequence: SequenceType) {
        updatePixels()
    }

    func sequenceSetPixelColor(_ sequence: SequenceType, point: Point, color: rpi_ws281x_swift.Color) {
        setPixelColor(point: point, color: color)
    }

    func sequenceSetPixelColor(_ sequence: SequenceType, pos: Int, color: rpi_ws281x_swift.Color) {
        setPixelColor(pos: pos, color: color)
    }
}

class LEDView: NSView {
    var leds: [Point: CAShapeLayer] = [:]
    var colors: [Color] = []

    func setup(numberOfLeds: Int, matrixWidth: Int, size: CGFloat) {
        let count = numberOfLeds / matrixWidth

        let mainlayer = CALayer()
        mainlayer.frame = self.bounds

        for pos in 0..<numberOfLeds {
            let y = pos / count
            let x = pos - (y * count)
            let point: Point = .init(x: x, y: y)
            let frame: CGRect = .init(x: point.cgPoint.x * size, y: point.cgPoint.y * size, width: size, height: size)

            let layer = CAShapeLayer()
            layer.path = CGPath(ellipseIn: frame, transform: nil)
            layer.fillColor = NSColor.blue.cgColor
            mainlayer.addSublayer(layer)
            leds[point] = layer
        }

        self.layer = mainlayer
    }

    func setPixelColor(point: Point, color: Color) {
        leds[point]?.fillColor = color.cgColor
    }
}

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    var controller: LedControllerProtocol
    var stop = false

    init(controller: LedControllerProtocol) {
        self.controller = controller
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        DispatchQueue.global().async {
            while self.stop == false {
                self.controller.runSequence()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension Color {
    var cgColor: CGColor {
        return CGColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1.0
        )
    }
}

extension Point {
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

#else

class WindowController: ConsoleController {

}

#endif
