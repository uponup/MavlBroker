//
//  MavlTimer.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/28.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

private enum State {
    case suspended
    case resumed
    case canceled
}

class MavlTimer {
    let timeInterval: TimeInterval
    let startDelay: TimeInterval
    
    var eventHandler: (() -> Void)?
    
    private var state: State = .suspended
    private lazy var _timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.startDelay, repeating: self.timeInterval > 0 ? Double(self.timeInterval) : Double.infinity)
        t.setEventHandler { [weak self] in
            self?.eventHandler?()
        }
        return t
    }()
    
    init(delay: TimeInterval? = nil, timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
        if let delay = delay {
            self.startDelay = delay
        }else {
            self.startDelay = timeInterval
        }
    }
    
    deinit {
        _timer.setEventHandler {}
        _timer.cancel()
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        _timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        _timer.suspend()
    }
    
    func cancel() {
        if state == .canceled {
            return
        }
        state = .canceled
        _timer.cancel()
    }
    
    // MARK: - class method
    class func every(_ interval: TimeInterval, _ block: @escaping () -> Void) -> MavlTimer {
        let timer = MavlTimer(timeInterval: interval)
        timer.eventHandler = block
        timer.resume()
        return timer
    }
    
    class func after(_ interval: TimeInterval, _ block: @escaping () -> Void) -> MavlTimer {
        var timer: MavlTimer? = MavlTimer(delay: interval, timeInterval: 0)
        timer?.eventHandler = {
            block()
            timer?.suspend()
            timer = nil
        }
        timer?.resume()
        return timer!
    }
}
