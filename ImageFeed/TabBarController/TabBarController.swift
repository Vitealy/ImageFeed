import UIKit

final class TabBarController: UITabBarController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
            setupViewControllers()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupViewControllers()
        }
    
    convenience init() {
            self.init(nibName: nil, bundle: nil)
        }
        
        private func setupViewControllers() {
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            
            let imagesListViewController = storyboard.instantiateViewController(
                withIdentifier: "ImagesListViewController"
            )
            
            let profileViewController = ProfileViewController()
            profileViewController.tabBarItem = UITabBarItem(
                title: "",
                image: UIImage(named: "tab_profile_active"),
                selectedImage: nil
            )
            
            self.viewControllers = [imagesListViewController, profileViewController]
            print("📱 [TabBarController] viewControllers созданы: \(self.viewControllers?.count ?? 0)")
        }
    
}
