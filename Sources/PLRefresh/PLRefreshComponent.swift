import UIKit

enum PLRefreshState: Int {
    case idle = 1
    case pulling
    case refreshing
    case willRefresh
    case noMoreData
}

typealias PLRefreshComponentAction = () -> Void

class PLRefreshComponent: UIView {
    var scrollViewOriginalInset: UIEdgeInsets = .zero
    weak var scrollView: UIScrollView?
    
    var fastAnimationDuration: TimeInterval = 0.25
    var slowAnimationDuration: TimeInterval = 0.4
    
    var refreshingBlock: PLRefreshComponentAction?
    var refreshingTarget: AnyObject?
    var refreshingAction: Selector?
    
    var state: PLRefreshState = .idle {
        didSet {
            setState(self.state)
        }
    }
    
    var pullingPercent: CGFloat = 0.0 {
        didSet {
            if self.isRefreshing { return }
            if self.isAutomaticallyChangeAlpha {
                self.alpha = pullingPercent
            }
        }
    }
    
    var isRefreshing: Bool {
        return self.state == .refreshing || self.state == .willRefresh
    }
    
    var isAutomaticallyChangeAlpha: Bool = false {
        didSet {
            if self.isRefreshing { return }
            if self.isAutomaticallyChangeAlpha {
                self.alpha = self.pullingPercent
            } else {
                self.alpha = 1.0
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.prepare()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.prepare()
    }
    
    override func layoutSubviews() {
        self.placeSubviews()
        super.layoutSubviews()
    }
    
    func setState(_ state: PLRefreshState) {
        self.setNeedsLayout()
    }
    
    func prepare() {
        self.autoresizingMask = .flexibleWidth
        self.backgroundColor = .clear
    }
    
    func placeSubviews() {}
    
    func scrollViewContentOffsetDidChange(change: [NSKeyValueChangeKey: Any]?) {}
    func scrollViewContentSizeDidChange(change: [NSKeyValueChangeKey: Any]?) {}
    func scrollViewPanStateDidChange(change: [NSKeyValueChangeKey: Any]?) {}
    
    func setRefreshing(target: AnyObject, action: Selector) {
        self.refreshingTarget = target
        self.refreshingAction = action
    }
    
    func beginRefreshing() {
        UIView.animate(withDuration: self.fastAnimationDuration) {
            self.alpha = 1.0
        }
        self.pullingPercent = 1.0
        if self.window != nil {
            self.state = .refreshing
        } else {
            if self.state != .refreshing {
                self.state = .willRefresh
                self.setNeedsDisplay()
            }
        }
    }
    
    func endRefreshing() {
        DispatchQueue.main.async {
            self.state = .idle
        }
    }
    
    func executeRefreshingCallback() {
        DispatchQueue.main.async {
            self.refreshingBlock?()
            if let target = self.refreshingTarget, let action = self.refreshingAction {
                _ = target.perform(action, with: self)
            }
        }
    }
}
