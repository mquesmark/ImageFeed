import UIKit
import ProgressHUD

@MainActor
final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    static func show(_ text: String? = nil) {
        
        DispatchQueue.main.async {
            window?.isUserInteractionEnabled = false
            ProgressHUD.animate(text)
        }
    }
    static func dismiss() {
        DispatchQueue.main.async {
            ProgressHUD.dismiss()
            window?.isUserInteractionEnabled = true
        }
    }
    static func changeAnimationStyle(to type: AnimationType, symbol: String? = nil) {
        ProgressHUD.animationType = type
        if type == AnimationType.sfSymbolBounce {
            ProgressHUD.animationSymbol = symbol ?? ""
        }
    }
    
    static func changeColor (to color: UIColor) {
        ProgressHUD.colorAnimation = color
    }
}

