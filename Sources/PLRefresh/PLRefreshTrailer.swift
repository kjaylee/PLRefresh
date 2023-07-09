import UIKit

class PLRefreshTrailer: PLRefreshComponent {
    let refreshTrailWidth: CGFloat = 50.0
    var lastRefreshCount: Int = 0
    var lastRightDelta: CGFloat = 0.0
    
    static func trailer(withRefreshingBlock refreshingBlock: @escaping PLRefreshComponentAction) -> PLRefreshTrailer {
        let trailer = PLRefreshTrailer()
        trailer.refreshingBlock = refreshingBlock
        return trailer
    }
    
    static func trailer(withRefreshingTarget target: AnyObject, refreshingAction: Selector) -> PLRefreshTrailer {
        let trailer = PLRefreshTrailer()
        trailer.setRefreshing(target: target, action: refreshingAction)
        return trailer
    }
    
    override func scrollViewContentOffsetDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentOffsetDidChange(change: change)
        
        // In refreshing state
        if self.state == .refreshing { return }
        
        // Current contentOffset
        let currentOffsetX = self.scrollView?.contentOffset.x ?? 0
        // The offsetX when the trailer just appears
        let happenOffsetX = self.happenOffsetX()
        
        // If it's scrolling left to make the trailer invisible, return
        if currentOffsetX <= happenOffsetX { return }
        
        let pullingPercent = (currentOffsetX - happenOffsetX) / self.frame.width
        
        // If all data is loaded, only set pullingPercent, then return
        if self.state == .noMoreData {
            self.pullingPercent = pullingPercent
            return
        }
        
        if self.scrollView?.isDragging == true { // If it's dragging
            self.pullingPercent = pullingPercent
            // The offsetX threshold to change from .idle to .pulling
            let normal2pullingOffsetX = happenOffsetX + self.frame.width
            
            if self.state == .idle && currentOffsetX > normal2pullingOffsetX {
                // Change to .pulling state
                self.state = .pulling
            } else if self.state == .pulling && currentOffsetX <= normal2pullingOffsetX {
                // Change to .idle state
                self.state = .idle
            }
        } else if self.state == .pulling { // About to refresh and the hand is released
            // Start refreshing
            self.beginRefreshing()
        } else if pullingPercent < 1 {
            self.pullingPercent = pullingPercent
        }
    }
    
    override func setState(_ state: PLRefreshState) {
        let oldState = self.state
        if oldState == state { return }
        super.setState(state)
        
        // Based on the state do something
        if state == .idle || state == .noMoreData {
            // Refreshing finished
            if oldState == .refreshing {
                UIView.animate(withDuration: self.slowAnimationDuration, animations: {
                    self.scrollView?.contentInset.right -= self.lastRightDelta
                    // Automatically adjust alpha
                    if self.isAutomaticallyChangeAlpha { self.alpha = 0.0 }
                }) { (finished) in
                    self.pullingPercent = 0.0
                }
            }
        } else if state == .refreshing {
            // Record the count of refresh before
            if let tableView = self.scrollView as? UITableView {
                self.lastRefreshCount = tableView.totalDataCount
            }
            if let collectionView = self.scrollView as? UICollectionView {
                self.lastRefreshCount = collectionView.totalDataCount
            }
            
            UIView.animate(withDuration: self.fastAnimationDuration, animations: {
                var right = self.frame.width + self.scrollViewOriginalInset.right
                let deltaW = self.widthForContentBreakView()
                if deltaW < 0 { // If content width is less than view's width
                    right -= deltaW
                }
                self.lastRightDelta = right - (self.scrollView?.contentInset.right ?? 0)
                self.scrollView?.contentInset.right = right
                
                // Set the scroll position
                var offset = self.scrollView?.contentOffset
                offset?.x = self.happenOffsetX() + self.frame.width
                self.scrollView?.setContentOffset(offset ?? CGPoint.zero, animated: false)
            }) { (finished) in
                self.executeRefreshingCallback()
            }
        }
    }

    
    override func scrollViewContentSizeDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentSizeDidChange(change: change)
        
        // Content's width
        let contentWidth = self.scrollView?.contentSize.width ?? 0
        // Table's width
        let scrollWidth = (self.scrollView?.frame.size.width ?? 0) - self.scrollViewOriginalInset.left - self.scrollViewOriginalInset.right
        // Set position and size
        self.frame.origin.x = max(contentWidth, scrollWidth)
    }
    
    override func placeSubviews() {
        super.placeSubviews()
        
        self.frame.size.height = self.scrollView?.frame.size.height ?? 0
        // Set self's width
        self.frame.size.width = refreshTrailWidth
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if newSuperview != nil {
            // Set to support horizontal spring effect
            self.scrollView?.alwaysBounceHorizontal = true
            self.scrollView?.alwaysBounceVertical = false
        }
    }
    
    func happenOffsetX() -> CGFloat {
        let deltaW = self.widthForContentBreakView()
        if deltaW > 0 {
            return deltaW - self.scrollViewOriginalInset.left
        } else {
            return -self.scrollViewOriginalInset.left
        }
    }
    
    func widthForContentBreakView() -> CGFloat {
        let w = (self.scrollView?.frame.size.width ?? 0) - self.scrollViewOriginalInset.right - self.scrollViewOriginalInset.left
        return (self.scrollView?.contentSize.width ?? 0) - w
    }
}
