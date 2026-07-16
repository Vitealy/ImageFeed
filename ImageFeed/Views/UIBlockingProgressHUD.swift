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
    
    private static var activityIndicator: UIActivityIndicatorView?
        
        static func show() {
            // Выполняем на главном потоке в следующем цикле RunLoop
            DispatchQueue.main.async {
                guard let window = window else {
                    print("❌ UIBlockingProgressHUD: окно не найдено")
                    return
                }
                
                // Проверяем, не показан ли уже индикатор
                if activityIndicator != nil { return }
                
                window.isUserInteractionEnabled = false
                
                let indicator = UIActivityIndicatorView(style: .large)
                indicator.color = .white
                indicator.center = window.center
                indicator.startAnimating()
                window.addSubview(indicator)
                
                activityIndicator = indicator
                print("🟢 UIBlockingProgressHUD: показан")
            }
        }
        
        static func dismiss() {
            DispatchQueue.main.async {
                activityIndicator?.removeFromSuperview()
                activityIndicator = nil
                window?.isUserInteractionEnabled = true
                print("🔴 UIBlockingProgressHUD: скрыт")
            }
        }
    
    
//    private static var isShowing = false
//    
//    static func show() {
//        print("🟢 show")
//        guard !isShowing else { return }
//        isShowing = true
//        window?.isUserInteractionEnabled = false
//        ProgressHUD.animate()
//    }
//    
//    static func dismiss() {
//        print("🔴 dismiss")
//        guard isShowing else { return }
//        isShowing = false
//        window?.isUserInteractionEnabled = true
//        ProgressHUD.dismiss()
//    }
}
