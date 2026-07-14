import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene})
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first
        else {
            return nil
        }
        return window
    }
    private static var isShowing = false
    
    static func show() {
        guard !isShowing else { return }
        isShowing = true
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    
    static func dismiss() {
        guard isShowing else { return }
        isShowing = false
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
