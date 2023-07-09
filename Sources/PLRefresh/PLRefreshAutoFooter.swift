#if canImport(UIKit)
import UIKit

class PLRefreshAutoFooter: PLRefreshFooter {
    var automaticallyRefresh: Bool = true
    var triggerAutomaticallyRefreshPercent: CGFloat = 1.0
    var autoTriggerTimes: Int = 1
    private var triggerByDrag: Bool = false
    private var leftTriggerTimes: Int = 0
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if newSuperview != nil {
            if !self.isHidden {
                self.scrollView?.contentInset.bottom += self.frame.height
            }
            
            // Set position
            self.frame.origin.y = self.scrollView?.contentSize.height ?? 0
        } else {
            if !self.isHidden {
                self.scrollView?.contentInset.bottom -= self.frame.height
            }
        }
    }
    
    override func prepare() {
        super.prepare()
        
        // By default, the footer control will automatically refresh when it appears 100%
        self.triggerAutomaticallyRefreshPercent = 1.0
        
        // Set to default state
        self.automaticallyRefresh = true
        
        self.autoTriggerTimes = 1
    }
    
    override func scrollViewContentSizeDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentSizeDidChange(change: change)
        
        // Set position
        self.frame.origin.y = (self.scrollView?.contentSize.height ?? 0) + self.ignoredScrollViewContentInsetBottom
    }
    
    override func scrollViewContentOffsetDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentOffsetDidChange(change: change)
        
        if self.state != .idle || !self.automaticallyRefresh || self.frame.origin.y == 0 { return }
        
        if let scrollView,
           scrollView.contentInset.top  + scrollView.contentSize.height > scrollView.frame.height,
           scrollView.contentOffset.y  >=
            scrollView.contentSize.height - scrollView.frame.height + self.frame.height * self.triggerAutomaticallyRefreshPercent + scrollView.contentInset.bottom  - self.frame.height {
            let old = change?[.oldKey] as? CGPoint
            let new = change?[.newKey] as? CGPoint
            if new?.y ?? 0 <= old?.y ?? 0 { return }
            
            if self.scrollView?.isDragging == true {
                self.triggerByDrag = true
            }
            
            // Start refreshing when the footer control fully appears
            self.beginRefreshing()
        }
    }
    
    override func scrollViewPanStateDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewPanStateDidChange(change: change)
        
        guard self.state == .idle,
              let scrollView else {
            return
        }
        
        let panState = scrollView.panGestureRecognizer.state
        
        switch panState {
        case .ended:
            if scrollView.contentInset.top + scrollView.contentSize.height <= scrollView.frame.height,
               scrollView.contentOffset.y >= -scrollView.contentInset.top {
                    self.triggerByDrag = true
                    self.beginRefreshing()
            } else if scrollView.contentOffset.y
                        >= scrollView.contentSize.height + scrollView.contentInset.bottom - scrollView.frame.height {
                    self.triggerByDrag = true
                    self.beginRefreshing()
            }
        case .began:
            self.resetTriggerTimes()
        default:
            break
        }
    }
    
    override func beginRefreshing() {
        if self.triggerByDrag && self.leftTriggerTimes <= 0 && !self.unlimitedTrigger() {
            return
        }
        
        super.beginRefreshing()
    }
    
    override func setState(_ state: PLRefreshState) {
        let oldState = self.state
        if oldState == state { return }
        super.setState(state)
        
        if state == .refreshing {
            self.executeRefreshingCallback()
        } else if state == .noMoreData || state == .idle {
            if self.triggerByDrag {
                if !self.unlimitedTrigger() {
                    self.leftTriggerTimes -= 1
                }
                self.triggerByDrag = false
            }
            
            if oldState == .refreshing {
                if self.scrollView?.isPagingEnabled == true {
                    var offset = self.scrollView?.contentOffset ?? .zero
                    offset.y -= self.scrollView?.contentInset.bottom ?? 0
                    UIView.animate(withDuration: self.slowAnimationDuration, animations: {
                        self.scrollView?.contentOffset = offset
                    })
                }
            }
        }
    }
    
    func resetTriggerTimes() {
        self.leftTriggerTimes = self.autoTriggerTimes
    }
    
    func unlimitedTrigger() -> Bool {
        return self.leftTriggerTimes == -1
    }
    
    override var isHidden: Bool {
        didSet {
            let lastHidden = super.isHidden
            
            super.isHidden = isHidden
            
            if !lastHidden && isHidden {
                self.state = .idle
                
                self.scrollView?.contentInset.bottom -= self.frame.height
            } else if lastHidden && !isHidden {
                self.scrollView?.contentInset.bottom += self.frame.height
                
                // Set position
                self.frame.origin.y = self.scrollView?.contentSize.height ?? 0
            }
        }
    }
}
#endif
