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
        case Break, Task
        
        func next() -> State {
            switch self {
            case .Break: return .Task
            default: return .Break
            }
        }
        
        func string() -> String {
            switch self {
            case .Break: return "B"
            default: return "T"
            }
        }
        
        func value() -> Int {
            switch self {
            case .Break: return 5
            default: return 25
            }
        }
    }
    
    @IBOutlet weak var pomMenu: NSMenu!
    
    let pomItem = NSStatusBar.systemStatusBar().statusItemWithLength(55)
    var pom : Pomodoro?    
    var state : State?
    var running = true
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        let mins = pom!.pause()
        updateLog("end", state!.string(), String(state!.value() - mins))
        updateLog("quit")
        NSApplication.sharedApplication().terminate(self);
    }
    
    @IBAction func startTask(sender: NSMenuItem) {
        let mins = pom!.pause()
        updateLog("end", state!.string(), String(state!.value() - mins))
        state = State.Task
        updateLog("begin", state!.string())
        pom?.start(mins: state!.value())
    }
    
    @IBAction func startBreak(sender: NSMenuItem) {
        let mins = pom!.pause()
        updateLog("end", state!.string(), String(state!.value() - mins))
        state = State.Break
        updateLog("begin", state!.string())
        pom?.start(mins: state!.value())
    }
    
    @IBAction func pause(sender: NSMenuItem) {
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
            state = State.Task;
        }
        pom!.start(mins: state!.value())
        updateLog("begin", state!.string())
    }
    
    func updateTitle(secs: Int) {
        let min = secs / 60
        let sec = secs % 60
        func nul(sec : Int) -> String { return sec < 10 ? "0" : "" }
        pomItem.title = (state?.string() ?? "") +
            "\(nul(min))\(min):\(nul(sec))\(sec)"
    }

    func updateLog(text: String...) {
        let path  = NSHomeDirectory() + "/.pomodoro.txt"
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let date = formatter.stringFromDate(NSDate())
        
        let info = [date] + text
        let line = info.joinWithSeparator("\t") + "\n"
        
        let os : NSOutputStream = NSOutputStream(toFileAtPath: path, append: true)!
        os.open()
        os.write(line, maxLength: line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        os.close()
    }
    
}

class Pomodoro {
    let pomCtl : PomMenuController
    var timer : NSTimer?
    var secs = 0
    
    init(ctl pomCtl : PomMenuController) {
        self.pomCtl = pomCtl
    }
    
    func pause() -> Int {
        timer?.invalidate()
        return Int(round(Float(secs) / 60.0))
    }
    
    func start(mins mins : Int?) {
        if let mins = mins { secs = mins * 60 }
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(
            1.0,
            target: self,
            selector: #selector(Pomodoro.timerFunc(_:)),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func timerFunc(timer : NSTimer) {
        if secs <= 0 { pomCtl.updateState() }
        pomCtl.updateTitle(secs)
        secs -= 1;
    }
    
    
}