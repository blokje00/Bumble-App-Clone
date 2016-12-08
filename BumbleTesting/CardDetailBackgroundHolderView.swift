//
//  CardDetailBackgroundHolderView.swift
//  BumbleTesting
//
//  Created by Daniel Jones on 12/5/16.
//  Copyright © 2016 Daniel Jones. All rights reserved.
//

import UIKit
import SnapKit

class CardDetailBackgroundHolderView: UIView {
    var theCardDetailView: CardDetailView!
    var pageControl: CustomPageControl!
    let minAlpha: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(minAlpha)
        cardDetailSetup()
        addCardDetailTapGesture()
        addBackgroundTapGesture()
        addPan()
        pageControlSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func cardDetailSetup() {
        theCardDetailView = CardDetailView(frameWidth: self.frame.width, frameMinY: self.bounds.maxY - 100, height: 100)
        theCardDetailView.backgroundColor = UIColor.red
        self.addSubview(theCardDetailView)
        theCardDetailView.setMaxFrame()
    }
    
    fileprivate func pageControlSetup() {
        pageControl = CustomPageControl()
        self.addSubview(pageControl)
        pageControl.snp.makeConstraints { (make) in
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.height.equalTo(100)
            make.width.equalTo(100)
        }
    }
    
    //allows us to check where the hit occurred and then decide if we want userInteraction for that point, or let it pass on to other views behind it. Basically like isUserInteractionEnabled, but we can choose individual points to be enabled.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if theCardDetailView.frame.contains(point) || theCardDetailView.isOpen {
            return true
        }
        //pass the tap onto other views
        return false
    }
}

//handle tap
extension CardDetailBackgroundHolderView {
    fileprivate func addBackgroundTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleDetailTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    fileprivate func addCardDetailTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleDetailTap(_:)))
        theCardDetailView.addGestureRecognizer(tap)
    }
    
    func handleDetailTap(_ sender: UIGestureRecognizer) {
        if theCardDetailView.isOpen {
            animateToOriginalFrame()
        } else {
            animateToMaxFrame()
        }
        pageControl.progress += 1
    }
}

//handlind pan
extension CardDetailBackgroundHolderView {
    func addPan() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.isPanning(pan:)))
        self.addGestureRecognizer(pan)
    }
    
    func isPanning(pan: UIPanGestureRecognizer) {
        let pointOfTouch = pan.location(in: self)
        let velocity = pan.velocity(in: self)
        
        var direction: UISwipeGestureRecognizerDirection?
        if velocity.y < 0 {
            direction = .up
        } else if velocity.y > 0 {
            direction = .down
        }
        
        self.pan(touchPoint: pointOfTouch, direction: direction, state: pan.state)
    }
    
    func pan(touchPoint: CGPoint, direction: UISwipeGestureRecognizerDirection?, state: UIGestureRecognizerState) {
        if state == .ended {
            if let direction = direction {
                finishSwipe(direction: direction)
            } else {
                finishNonVelocityDrag()
            }
        } else {
            animateDetailView(pointOfTouch: touchPoint)
        }
    }
    
    fileprivate func finishSwipe(direction: UISwipeGestureRecognizerDirection) {
        if direction == .up {
            animateToMaxFrame()
        } else if direction == .down {
            animateToOriginalFrame()
        }
    }
    
    fileprivate func finishNonVelocityDrag() {
        if theCardDetailView.frame.minY <= theCardDetailView.finishSwipeThresholdY {
            animateToMaxFrame()
        } else {
            animateToOriginalFrame()
        }
    }
    
    fileprivate func animateToMaxFrame() {
        animateDetailView(pointOfTouch: theCardDetailView.maxFrame.origin)
    }
    
    fileprivate func animateToOriginalFrame() {
        animateDetailView(pointOfTouch: theCardDetailView.originalFrame.origin)
    }
    
    fileprivate func animateDetailView(pointOfTouch: CGPoint) {
        UIView.animate(withDuration: 0.3, animations: {
            //open being when the cardDetail is showing its inner contents
            let openY = self.theCardDetailView.maxFrame.minY
            let closedY = self.theCardDetailView.originalFrame.minY
            let openInset = self.theCardDetailView.originalFrameInset
            let closedInset = self.theCardDetailView.maxFrameInset
            
            var currentTouchY = pointOfTouch.y
            if currentTouchY < openY {
                currentTouchY = openY
            } else if currentTouchY > closedY {
                currentTouchY = closedY
            }
            
            let percentOpened = (closedY - currentTouchY) / (closedY - openY)
            let inset = (1 - percentOpened) * (openInset - closedInset) + closedInset
            self.theCardDetailView.frame = CGRect(x: inset, y: currentTouchY, width: self.frame.maxX - inset * 2, height: self.frame.maxY - currentTouchY - inset)
            self.updateAlpha(percentOpened: percentOpened)
        })
    }
    
    fileprivate func updateAlpha(percentOpened: CGFloat) {
        let maxAlpha: CGFloat = 0.8
        let alphaDifference = maxAlpha - minAlpha
        let targetAlpha = (alphaDifference * percentOpened) + minAlpha
        self.backgroundColor = self.backgroundColor?.withAlphaComponent(targetAlpha)
    }
}
