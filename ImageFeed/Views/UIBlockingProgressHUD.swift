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
    
    static var verticalOffset: CGFloat = 70
    
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
            
            
            // ✅ Центр с учётом смещения
            let centerX = window.center.x
            let centerY = window.center.y + verticalOffset
            indicator.center = CGPoint(x: centerX, y: centerY)
            
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
    
}
