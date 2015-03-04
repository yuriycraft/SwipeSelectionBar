//
//  SwipeSelectionBar.swift
//  SwipeSelectionBar
//
//  Created by TracyYih on 15/3/4.
//  Copyright (c) 2015年 esoftmobile.com. All rights reserved.
//

import UIKit

class SwipeSelectionBar: UIToolbar {
    
    private weak var textView: UITextView!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var previousPosition = CGPointZero
    private var rightSwipeSelected = false
    private var leftSwipeSelected = false
    private struct Constants{
        static let xMinimum: CGFloat = 10
        static let selectionWidth: CGFloat = 30
    }
    private enum SwipeDirection: Int {
        case Left, Right
    }
    
    var menuControllerEnable = true
    var swipeEnable: Bool = true {
        didSet {
            panGestureRecognizer.enabled = swipeEnable
        }
    }
    
    deinit {
        textView.removeObserver(self, forKeyPath: "selectedTextRange")
    }
    
    required init(textView: UITextView) {
        super.init()
        self.textView = textView
        self.frame = CGRectMake(0, 0, 0, 44)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "panAction:")
        panGestureRecognizer.cancelsTouchesInView = false
        self.addGestureRecognizer(panGestureRecognizer)
        
        textView.addObserver(self, forKeyPath: "selectedTextRange", options: .New, context: nil)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if textView.isEqual(object) && keyPath == "selectedTextRange" {
            if let selectedTextRange = textView.selectedTextRange {
                if selectedTextRange.empty {
                    leftSwipeSelected = false
                    rightSwipeSelected = false
                }
            } else {
                leftSwipeSelected = false
                rightSwipeSelected = false
            }
        }
    }
    
    // MARK: - Custom Methods
    private func swiped(direction: SwipeDirection, selected: Bool) {
        if let selectedTextRange = textView?.selectedTextRange {
            let positionStart = selectedTextRange.start
            let positionEnd = selectedTextRange.end
            let empty = selectedTextRange.empty
            
            var fromPosition: UITextPosition?
            var toPosition: UITextPosition?
            
            if direction == .Left {
                if empty {
                    fromPosition = textView.positionFromPosition(positionEnd, inDirection: .Left, offset: 1)
                    toPosition = selected ? positionStart: fromPosition
                    leftSwipeSelected = selected
                } else {
                    if rightSwipeSelected {
                        fromPosition = positionStart
                        toPosition = textView.positionFromPosition(positionEnd, inDirection: .Left, offset: 1)
                    } else {
                        fromPosition = textView.positionFromPosition(positionStart, inDirection: .Left, offset: 1)
                        toPosition = positionEnd
                    }
                }
                let textRange = textView.textRangeFromPosition(fromPosition, toPosition: toPosition)
                textView.selectedTextRange = textRange
            } else if direction == .Right {
                if empty {
                    fromPosition = textView.positionFromPosition(positionStart, inDirection: .Right, offset: 1)
                    toPosition = selected ? positionEnd: fromPosition
                    rightSwipeSelected = selected
                } else {
                    if leftSwipeSelected {
                        fromPosition = textView.positionFromPosition(positionStart, inDirection: .Right, offset: 1)
                        toPosition = positionEnd
                    } else {
                        fromPosition = positionStart
                        toPosition = textView.positionFromPosition(positionEnd, inDirection: .Right, offset: 1)
                    }
                }
                let textRange = textView.textRangeFromPosition(fromPosition, toPosition: toPosition)
                textView.selectedTextRange = textRange
            }
        }
    }
    
    private func showMenuController() {
        if let selectedTextRange = textView?.selectedTextRange {
            if !selectedTextRange.empty {
                let rect = textView.firstRectForRange(selectedTextRange)
                let menuController = UIMenuController.sharedMenuController()
                menuController.setTargetRect(rect, inView: textView)
                menuController.setMenuVisible(true, animated: true)
            }
        }
    }
    
    func panAction(gesture: UIPanGestureRecognizer) {
        if gesture.state == .Began {
            previousPosition = gesture.locationInView(self)
        } else if gesture.state == .Changed {
            gesture.cancelsTouchesInView = true
            
            let position = gesture.locationInView(self)
            let delta = CGPointMake(position.x - previousPosition.x, position.y - previousPosition.y)
            
            if delta.x > Constants.xMinimum {
                let selected = previousPosition.x < Constants.selectionWidth
                swiped(.Right, selected: selected)
                previousPosition = position
            } else if delta.x < -Constants.xMinimum {
                let selected = previousPosition.x > CGRectGetWidth(self.bounds) - Constants.selectionWidth
                swiped(.Left, selected: selected)
                previousPosition = position
            }
        } else  {
            previousPosition = CGPointZero
            gesture.cancelsTouchesInView = false
            if menuControllerEnable {
                showMenuController()
            }
        }
    }
}
