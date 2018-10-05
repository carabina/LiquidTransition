//
//  TransitionPercentAnimator.swift
//  CardsNavigation
//
//  Created by Alexander Graschenkov on 22.08.2018.
//  Copyright © 2018 Alex Development. All rights reserved.
//

import UIKit

protocol TransitionPercentAnimatorDelegate: class {
    func transitionPercentChanged(_ percent: CGFloat)
}

class InvertableInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var backward = false
    private(set) var percent: CGFloat = 0
    
    override var percentComplete: CGFloat {
        get { return backward ? 1.0-super.percentComplete : super.percentComplete }
    }
    override func update(_ percentComplete: CGFloat) {
        percent = percentComplete
        var val = backward ? 1.0-percent : percent
        val = min(val, 1)
        super.update(val)
    }
}

class TransitionPercentAnimator: InvertableInteractiveTransition {
    
    fileprivate var cancelAnimation: Cancelable?
    fileprivate(set) var lastSpeed: CGFloat = 0
    fileprivate(set) var lastUpdateTime: TimeInterval = 0
    weak var context: UIViewControllerContextTransitioning?
    var totalDuration: Double = 0
    var maxDurationFactor: Double = 2.0
    lazy var timing: LiTiming = LiTiming.default
    var isCanceled: Bool = false
    
    var enableSmothInteractive: Bool = false
    var smothInteractiveDuration: TimeInterval = 0.2
    fileprivate lazy var smothInteractive = SmothInteractive()
    
    weak var delegate: TransitionPercentAnimatorDelegate?
    
    func getDurationToState(finish: Bool, speed: CGFloat = 0) -> CGFloat {
        let fromPercent = percent
        let toPercent: CGFloat = finish ? 1.0 : 0.0
        var speedUp: CGFloat = 1.0
        if speed > 0 {
            speedUp = speed
        }
        var animDuration = duration * abs(toPercent - fromPercent) / speedUp
        // duration must be not too long
        animDuration =  min(duration * CGFloat(maxDurationFactor), animDuration)
        return animDuration
    }
    
    func animate(finish: Bool, speed: CGFloat = 0) {
        cancelAnimation?()
        
        let fromPercent = percent
        let toPercent: CGFloat = finish ? 1.0 : 0.0
        let animDuration = getDurationToState(finish: finish, speed:  speed)
        print("Animate " + (finish ? "finish" : "cancel"))
        
        cancelAnimation = DisplayLinkAnimator.animate(duration: Double(animDuration), closure: { (percent) in
            var percentMaped = self.timing.getValue(x: percent)
            percentMaped = (toPercent - fromPercent) * percentMaped + fromPercent
            super.update(percentMaped)
            self.delegate?.transitionPercentChanged(percentMaped)
            
            if (percent == 1) {
                print((finish ? "finished" : "canceled"))
                if finish {
                    self.finish()
                } else {
                    self.backward = false
                    super.update(0)
                    self.cancel()
                }
                
                self.context?.completeTransition(finish)
            }
        })
    }
    
    func pauseAnimation() {
        cancelAnimation?()
        cancelAnimation = nil
    }
    
    override func update(_ percentComplete: CGFloat) {
        let isAnimated = (cancelAnimation != nil)
        cancelAnimation?()
        cancelAnimation = nil
        
        let isSmothInteractive = performSmothInteractive(percent: percentComplete, canInitalize: isAnimated)
        if isSmothInteractive {
            // animation control take SmothInteractive class
        } else {
            internalUpdate(percentComplete)
        }
    }
    
    func needFinish() -> Bool {
        if lastSpeed == 0 {
            return percent > 0.4
        } else {
            return lastSpeed > 0
        }
    }
    
    
    // MARK: - private
    
    fileprivate func internalUpdate(_ percentComplete: CGFloat) {
        updateSpeedWith(percentComplete: percentComplete)
        super.update(percentComplete)
        delegate?.transitionPercentChanged(percent)
    }
    
    fileprivate func performSmothInteractive(percent percentComplete: CGFloat, canInitalize: Bool) -> Bool {
        if !enableSmothInteractive { return false }
        
        if canInitalize && percentComplete > 0.05 {
            smothInteractive.run(duration: smothInteractiveDuration) {[weak self] (val) in
                self?.internalUpdate(val)
            }
        }
        
        if smothInteractive.isRunning {
            smothInteractive.update(val: percentComplete)
            return true
        }
        
        return false
    }
    
    fileprivate func updateSpeedWith(percentComplete: CGFloat) {
        let currTime = CACurrentMediaTime()
        if lastUpdateTime == 0 {
            if (percentComplete - self.percentComplete) > 0 {
                lastSpeed = 1.0 / duration
            } else {
                lastSpeed = -1.0 / duration
            }
        } else {
            lastSpeed = (percentComplete - self.percentComplete) / CGFloat(currTime - lastUpdateTime)
        }
        lastUpdateTime = currTime
    }
    
    internal func reset() {
        lastSpeed = 0
        lastUpdateTime = 0
        backward = false
    }
}