//
//  PomMenuController.swift
//  Pomodoro for macOS
//
//  Created by Marek Černý on 03/09/16.
//  Copyright © 2016 Marek Cerny. All rights reserved.
//

import Cocoa
import Foundation

class PomMenuController: NSObject {
    
    enum State : Int {
        case `break`, task
        
        func next() -> State {
            switch self {
            case .break: return .task
            default: return .break
            }
        }
        
        func string() -> String {
            switch self {
            case .break: return "B"
            default: return "T"
            }
        }
        
        func value() -> Int {
            switch self {
            case .break: return 5
            default: return 25
            }
        }
    }
    
    @IBOutlet weak var pomMenu: NSMenu!
    
    let pomItem = NSStatusBar.system().statusItem(withLength: 55)
    let spotify: MusicControler = SpotifyControler()
    var pom: Pomodoro?
    var state: State? {
        didSet {
            let alert = NSAlert()
            if state == .break {
                spotify.play()
            } else {
                spotify.pause()
            }
            alert.runModal()
        }
    }
    var running = true
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        let mins = pom!.pause()
        updateLog("end", state!.string(), String(state!.value() - mins))
        updateLog("quit")
        NSApplication.shared().terminate(self);
    }
    
    @IBAction func startTask(_ sender: NSMenuItem) {
        let mins = pom!.pause()
        updateLog("end", state!.string(), String(state!.value() - mins))
        state = State.task
        updateLog("begin", state!.string())
        pom?.start(mins: state!.value())
        running = true;
    }
    
    @IBAction func startBreak(_ sender: NSMenuItem) {
        let mins = pom!.pause()
        updateLog("end", state!.string(), String(state!.value() - mins))
        state = State.break
        updateLog("begin", state!.string())
        pom?.start(mins: state!.value())
        running = true;
    }
    
    @IBAction func pause(_ sender: NSMenuItem) {
        if self.running {
            sender.title = "Continue"
            pom!.pause()
            updateLog("paused", state!.string())
        } else {
            sender.title = "Pause"
            pom!.start(mins: nil)
            updateLog("continued", state!.string())
        }
        self.running = !self.running
    }
    
    override func awakeFromNib() {
        // Insert code here to initialize your application
        pomItem.menu = pomMenu
        
        updateTitle(0)
        updateLog("started")

        pom = Pomodoro(ctl: self)
        updateState()
    }
    
    func updateState() {
        if let state = self.state {
            updateLog("end", state.string(), String(state.value()))
            self.state = state.next()
        } else {
            state = State.task;
        }
        pom!.start(mins: state!.value())
        updateLog("begin", state!.string())
    }
    
    func updateTitle(_ secs: Int) {
        let min = secs / 60
        let sec = secs % 60
        func nul(_ sec : Int) -> String { return sec < 10 ? "0" : "" }
        pomItem.title = (state?.string() ?? "") +
            "\(nul(min))\(min):\(nul(sec))\(sec)"
    }

    func updateLog(_ text: String...) {
        let path  = NSHomeDirectory() + "/.pomodoro.txt"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let date = formatter.string(from: Date())
        
        let info = [date] + text
        let line = info.joined(separator: "\t") + "\n"
        
        let os : OutputStream = OutputStream(toFileAtPath: path, append: true)!
        os.open()
        os.write(line, maxLength: line.lengthOfBytes(using: String.Encoding.utf8))
        os.close()
    }
    
}

class Pomodoro {
    let pomCtl : PomMenuController
    var timer : Timer?
    var secs = 0
    
    init(ctl pomCtl : PomMenuController) {
        self.pomCtl = pomCtl
    }
    
    func pause() -> Int {
        timer?.invalidate()
        return Int(round(Float(secs) / 60.0))
    }
    
    func start(mins : Int?) {
        if let mins = mins { secs = mins * 60 }
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(Pomodoro.timerFunc(_:)),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func timerFunc(_ timer : Timer) {
        if secs <= 0 { pomCtl.updateState() }
        pomCtl.updateTitle(secs)
        secs -= 1;
    }
    
}



protocol MusicControler {
    func play()
    func pause()
}

class SpotifyControler : MusicControler {
    
    private func run(command: String) -> Void {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "tell application \"Spotify\"", "-e", command, "-e", "end tell"]
        task.launch()

    }
    
    public func pause() { self.run(command: "pause") }
    public func play() { self.run(command: "play") }
}







