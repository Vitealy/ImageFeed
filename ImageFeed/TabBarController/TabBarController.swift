import UIKit

final class TabBarController: UITabBarController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupViewControllers()
        }
    
    // MARK: - Private Methods
        
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
