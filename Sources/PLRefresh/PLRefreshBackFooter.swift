//
//  PLRefreshBackFooter.swift
//  PLRefresh
//
//
import UIKit

class PLRefreshBackFooter: PLRefreshFooter {
    var lastRefreshCount: Int = 0
    var lastBottomDelta: CGFloat = 0.0

    // MARK: - 초기화
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        scrollViewContentSizeDidChange(change: nil)
    }

    // MARK: - 부모 클래스의 메서드 구현
    override func scrollViewContentOffsetDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentOffsetDidChange(change: change)
        
        // 만약 새로고침 중이라면, 바로 반환
        if state == .refreshing { return }
        
        scrollViewOriginalInset = scrollView?.contentInset ?? UIEdgeInsets.zero
        
        // 현재의 contentOffset
        let currentOffsetY = scrollView?.contentOffset.y ?? 0
        // 푸터가 정확히 보이는 offsetY
        let happenOffsetY = happenOffsetY()
        // 만약 아래로 스크롤하여 푸터를 볼 수 없다면, 바로 반환
        if currentOffsetY <= happenOffsetY { return }
        
        let pullingPercent = (currentOffsetY - happenOffsetY) / height
        
        // 만약 모두 로드되었다면, pullingPercent만 설정하고 반환
        if state == .noMoreData {
            self.pullingPercent = pullingPercent
            return
        }
        
        if scrollView?.isDragging ?? false {
            self.pullingPercent = pullingPercent
            // 일반 및 새로고침 상태의 경계점
            let normal2pullingOffsetY = happenOffsetY + height
            
            if state == .idle && currentOffsetY > normal2pullingOffsetY {
                // 새로고침 상태로 전환
                state = .pulling
            } else if state == .pulling && currentOffsetY <= normal2pullingOffsetY {
                // 일반 상태로 전환
                state = .idle
            }
        } else if state == .pulling { // 새로고침 상태 && 손을 놓음
            // 새로고침 시작
            beginRefreshing()
        } else if pullingPercent < 1 {
            self.pullingPercent = pullingPercent
        }
    }

    override func scrollViewContentSizeDidChange(change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentSizeDidChange(change: change)
        
        let size = change?[NSKeyValueChangeKey.newKey] as? CGSize ?? CGSize.zero
        var contentHeight = size.height == 0 ? scrollView?.contentH ?? 0 : size.height
        // 컨텐츠의 높이
        contentHeight += ignoredScrollViewContentInsetBottom
        // 테이블의 높이
        let scrollHeight = scrollView?.height ?? 0 - scrollViewOriginalInset.top - scrollViewOriginalInset.bottom + ignoredScrollViewContentInsetBottom
        // 위치 설정
        let y = max(contentHeight, scrollHeight)
        if y != y {
            self.y = y
        }
    }

    override var state: PLRefreshState {
        didSet {
            // 상태에 따라 속성 설정
            if state == .noMoreData || state == .idle {
                // 새로고침 완료
                if oldValue == .refreshing {
                    UIView.animate(withDuration: slowAnimationDuration, animations: {
                        self.endRefreshingAnimationBeginAction?()
                        
                        self.scrollView?.insetB -= self.lastBottomDelta
                        // 자동으로 투명도 조정
                        if self.isAutomaticallyChangeAlpha { self.alpha = 0.0 }
                    }, completion: { (finished) in
                        self.pullingPercent = 0.0
                        
                        self.endRefreshingCompletionBlock?()
                    })
                }
                
                let deltaH = heightForContentBreakView()
                // 새로고침 완료 직후
                if oldValue == .refreshing && deltaH > 0 && scrollView?.totalDataCount != lastRefreshCount {
                    scrollView?.contentOffset.y = scrollView?.contentOffset.y ?? 0
                }
            } else if state == .refreshing {
                // 새로고침 전의 수량 기록
                lastRefreshCount = scrollView?.totalDataCount ?? 0
                
                UIView.animate(withDuration: fastAnimationDuration, animations: {
                    var bottom = self.height + self.scrollViewOriginalInset.bottom
                    let deltaH = self.heightForContentBreakView()
                    if deltaH < 0 { // 만약 컨텐츠 높이가 뷰의 높이보다 작다면
                        bottom -= deltaH
                    }
                    self.lastBottomDelta = bottom - (self.scrollView?.insetB ?? 0)
                    self.scrollView?.insetB = bottom
                    self.scrollView?.contentOffset.y = self.happenOffsetY() + self.height
                }, completion: { (finished) in
                    self.executeRefreshingCallback()
                })
            }
        }
    }

    // MARK: - Private Methods
    // MARK: 스크롤뷰의 컨텐츠가 뷰의 높이를 초과하는 경우
    private func heightForContentBreakView() -> CGFloat {
        let h = scrollView?.frame.size.height ?? 0 - scrollViewOriginalInset.bottom - scrollViewOriginalInset.top
        return (scrollView?.contentSize.height ?? 0) - h
    }

    // MARK: 푸터를 정확히 볼 수 있는 contentOffset.y
    private func happenOffsetY() -> CGFloat {
        let deltaH = heightForContentBreakView()
        if deltaH > 0 {
            return deltaH - scrollViewOriginalInset.top
        } else {
            return -scrollViewOriginalInset.top
        }
    }
}
