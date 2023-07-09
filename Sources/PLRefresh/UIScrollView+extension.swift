import UIKit

private var adjustedContentInsetKey: UInt8 = 0

extension UIScrollView {
    var ignoredScrollViewContentInsetBottom: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ignoredScrollViewContentInsetBottom) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ignoredScrollViewContentInsetBottom, newValue as CGFloat, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private struct AssociatedKeys {
        static var ignoredScrollViewContentInsetBottom = "ignoredScrollViewContentInsetBottom"
    }
}

extension UIScrollView {
    private static let onceToken = UUID().uuidString

    static let respondsToAdjustedContentInset: Bool = {
        var result = false
        DispatchQueue.once(token: onceToken) {
            let instance = UIScrollView()
            result = instance.responds(to: #selector(getter: adjustedContentInset))
        }
        return result
    }()

    var inset: UIEdgeInsets {
        if #available(iOS 11.0, *), UIScrollView.respondsToAdjustedContentInset {
            return self.adjustedContentInset
        }
        return self.contentInset
    }

    var insetT: CGFloat {
        get {
            return self.inset.top
        }
        set {
            var inset = self.contentInset
            inset.top = newValue
            if #available(iOS 11.0, *), UIScrollView.respondsToAdjustedContentInset {
                inset.top -= (self.adjustedContentInset.top - self.contentInset.top)
            }
            self.contentInset = inset
        }
    }

    var insetB: CGFloat {
        get {
            return self.inset.bottom
        }
        set {
            var inset = self.contentInset
            inset.bottom = newValue
            if #available(iOS 11.0, *), UIScrollView.respondsToAdjustedContentInset {
                inset.bottom -= (self.adjustedContentInset.bottom - self.contentInset.bottom)
            }
            self.contentInset = inset
        }
    }

    var insetL: CGFloat {
        get {
            return self.inset.left
        }
        set {
            var inset = self.contentInset
            inset.left = newValue
            if #available(iOS 11.0, *), UIScrollView.respondsToAdjustedContentInset {
                inset.left -= (self.adjustedContentInset.left - self.contentInset.left)
            }
            self.contentInset = inset
        }
    }

    var insetR: CGFloat {
        get {
            return self.inset.right
        }
        set {
            var inset = self.contentInset
            inset.right = newValue
            if #available(iOS 11.0, *), UIScrollView.respondsToAdjustedContentInset {
                inset.right -= (self.adjustedContentInset.right - self.contentInset.right)
            }
            self.contentInset = inset
        }
    }

    var offsetX: CGFloat {
        get {
            return self.contentOffset.x
        }
        set {
            var offset = self.contentOffset
            offset.x = newValue
            self.contentOffset = offset
        }
    }

    var offsetY: CGFloat {
        get {
            return self.contentOffset.y
        }
        set {
            var offset = self.contentOffset
            offset.y = newValue
            self.contentOffset = offset
        }
    }

    var contentW: CGFloat {
        get {
            return self.contentSize.width
        }
        set {
            var size = self.contentSize
            size.width = newValue
            self.contentSize = size
        }
    }

    var contentH: CGFloat {
        get {
            return self.contentSize.height
        }
        set {
            var size = self.contentSize
            size.height = newValue
            self.contentSize = size
        }
    }
    
    var totalDataCount: Int {
        if let v = self as? UITableView {
            var totalCount = 0
            for section in 0..<v.numberOfSections {
                totalCount += v.numberOfRows(inSection: section)
            }
            return totalCount
        } else if let v = self as? UICollectionView {
            var totalCount = 0
            for section in 0..<v.numberOfSections {
                totalCount += v.numberOfItems(inSection: section)
            }
            return totalCount
        } else {
            return 0
        }
    }
}

extension DispatchQueue {
    static func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}

private var _onceTracker = [String]()

