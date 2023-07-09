#if canImport(UIKit)
import UIKit

class PLRefreshHeader: PLRefreshComponent {
    var endRefreshingCompletionBlock: (() -> Void)?
    var insetTDelta: CGFloat = 0.0
    var lastUpdatedTimeKey: String = "PLRefreshHeaderLastUpdatedTimeKey"
    var lastUpdatedTime: Date? {
        return UserDefaults.standard.object(forKey: self.lastUpdatedTimeKey) as? Date
    }
    
    static func header(withRefreshingBlock refreshingBlock: @escaping PLRefreshComponentAction) -> PLRefreshHeader {
        let header = PLRefreshHeader()
        header.refreshingBlock = refreshingBlock
        return header
    }
    
    static func header(withRefreshingTarget target: AnyObject, refreshingAction: Selector) -> PLRefreshHeader {
        let header = PLRefreshHeader()
        header.setRefreshing(target: target, action: refreshingAction)
        return header
    }
    
    override func prepare() {
        super.prepare()
        self.frame.size.height = 44.0 // Set your header height
    }
    
    override func scrollViewContentOffsetDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentOffsetDidChange(change: change)
        
        // In refreshing state
        if self.state == .refreshing {
            return
        }
        
        // Current contentOffset
        let offsetY = self.scrollView?.contentOffset.y ?? 0
        // The offsetY when the header just appears
        let happenOffsetY = -self.scrollViewOriginalInset.top
        
        // If it's scrolling upwards to make the header invisible, return
        if offsetY > happenOffsetY { return }
        
        // The offsetY threshold to change from .idle to .pulling
        let normal2pullingOffsetY = happenOffsetY - self.frame.height
        let pullingPercent = (happenOffsetY - offsetY) / self.frame.height
        
        if self.scrollView?.isDragging == true { // If it's dragging
            self.pullingPercent = pullingPercent
            if self.state == .idle && offsetY < normal2pullingOffsetY {
                // Change to .pulling state
                self.state = .pulling
            } else if self.state == .pulling && offsetY >= normal2pullingOffsetY {
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
        if state == .idle {
            if oldState != .refreshing { return }
            
            // Save the refresh time
            UserDefaults.standard.set(Date(), forKey: self.lastUpdatedTimeKey)
            UserDefaults.standard.synchronize()
            
            // Recover the inset and offset
            UIView.animate(withDuration: 0.4, animations: {
                self.scrollView?.contentInset.top += self.insetTDelta
                
                if self.isAutomaticallyChangeAlpha { self.alpha = 0.0 }
            }) { (finished) in
                self.pullingPercent = 0.0
                
                if let endRefreshingCompletionBlock = self.endRefreshingCompletionBlock {
                    endRefreshingCompletionBlock()
                }
            }
        } else if state == .refreshing {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    let top = self.scrollViewOriginalInset.top + self.frame.height
                    // Increase the scroll area from the top
                    self.scrollView?.contentInset.top = top
                    // Set the scroll position
                    self.scrollView?.contentOffset = CGPoint(x: 0, y: -top)
                }) { (finished) in
                    self.executeRefreshingCallback()
                }
            }
        }
    }
}

#endif
