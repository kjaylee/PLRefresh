import UIKit

class PLRefreshFooter: PLRefreshComponent {
    let refreshFooterHeight: CGFloat = 50.0
    var ignoredScrollViewContentInsetBottom: CGFloat = 0.0
    var endRefreshingAnimationBeginAction: (() -> Void)?
    var endRefreshingCompletionBlock: (() -> Void)?


    static func footer(withRefreshingBlock refreshingBlock: @escaping PLRefreshComponentAction) -> PLRefreshFooter {
        let footer = PLRefreshFooter()
        footer.refreshingBlock = refreshingBlock
        return footer
    }
    
    static func footer(withRefreshingTarget target: AnyObject, refreshingAction: Selector) -> PLRefreshFooter {
        let footer = PLRefreshFooter()
        footer.setRefreshing(target: target, action: refreshingAction)
        return footer
    }
    
    override func prepare() {
        super.prepare()
        self.frame.size.height = refreshFooterHeight // Set your footer height
    }
    
    func endRefreshingWithNoMoreData() {
        DispatchQueue.main.async {
            self.state = .noMoreData
        }
    }
    
    func resetNoMoreData() {
        DispatchQueue.main.async {
            self.state = .idle
        }
    }
}
