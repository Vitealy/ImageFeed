import UIKit

final class ProfileViewController: UIViewController {
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var loginNameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    @IBOutlet private weak var loginButton: UIButton!
    
    @IBAction private func didTapLogoutButton() {
        
    }
    
}
