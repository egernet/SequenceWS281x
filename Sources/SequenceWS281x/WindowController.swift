//
//  File.swift
//  
//
//  Created by Christian Skaarup Enevoldsen on 05/10/2023.
//

import Foundation
import Cocoa
import rpi_ws281x_swift

class WindowController: LedControllerProtocol {
    let numberOfLeds: Int
    let matrixWidth: Int
    let sequences: [SequenceType]

    let window: NSWindow
    let contentView: LEDView

    init(sequences: [SequenceType], numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
        self.sequences = sequences

        let rowNumber = numberOfLeds / matrixWidth
        let mask: NSWindow.StyleMask = [.titled, .closable]
        let rect = NSMakeRect(0, 0, CGFloat(rowNumber * 30), CGFloat(matrixWidth * 30))
        self.window = NSWindow(contentRect: rect, styleMask: mask, backing: NSWindow.BackingStoreType.buffered, defer: false)

        self.contentView = LEDView()

        setup()
    }

    func setup() {
        window.contentView = contentView

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
        let point = Point(x: 0, y: 1)
        Console.moveCursor(point)
    }

    private func setPixelColor(point: Point, color: Color) {
        if point.x == 0 && point.y > 0 {
            Console.writeLine("")
        }
        Console.write("● ", color: color)
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

class LEDView : NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.red.set()
        dirtyRect.fill()
    }
}

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    var controller: LedControllerProtocol
    init(controller: LedControllerProtocol) {
        self.controller = controller
    }

    private func applicationDidFinishLaunching(notification: NSNotification) {
        DispatchQueue.global().sync {
            while(true) {
                self.controller.runSequence()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
