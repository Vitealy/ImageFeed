import UIKit
import Kingfisher

// MARK: - Protocol
protocol ProfileViewProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func displayProfile(_ profile: Profile)
    func displayAvatar(with url: URL)
    func showError(_ message: String)
    func showLogoutConfirmation()
}

final class ProfileViewController: UIViewController, ProfileViewProtocol {
    
    // MARK: - UI Elements
    private var profileImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    // MARK: - Properties
    var presenter: ProfilePresenterProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupProfileElements()
        presenter?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }
    
    // MARK: - Configuration (for tests)
        func configure(with presenter: ProfilePresenterProtocol) {
            self.presenter = presenter
            presenter.view = self
        }
    
    // MARK: - Setup UI
    private func setupProfileElements() {
        
        // MARK: - Avatar image
        
        profileImageView = UIImageView()
        profileImageView.accessibilityIdentifier = "ProfileAvatarImage"
        profileImageView = UIImageView(image: UIImage(named: "tab_profile_active"))
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 35
        profileImageView.layer.masksToBounds = true
        view.addSubview(profileImageView)
        
        // MARK: - Name Label
        
        nameLabel = UILabel()
        nameLabel.accessibilityIdentifier = "ProfileNameLabel"
        nameLabel.text = "Загрузка..."
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = .ypWhite
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        // MARK: - Login Name Label
        
        loginNameLabel = UILabel()
        loginNameLabel.accessibilityIdentifier = "ProfileUsernameLabel"
        loginNameLabel.text = "Загрузка..."
        loginNameLabel.font  = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = .ypGray
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        // MARK: - Description Label
        
        descriptionLabel = UILabel()
        descriptionLabel.accessibilityIdentifier = "ProfileDescriptionLabel"
        descriptionLabel.text = "Загрузка..."
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // MARK: - Logout Button
        
        logoutButton = UIButton(type: .system)
        logoutButton.accessibilityIdentifier = "logoutButton"
        let logoutImage = UIImage(systemName: "ipad.and.arrow.forward")
        logoutButton.setImage(logoutImage, for: .normal)
        logoutButton.tintColor = .ypRed
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        view.addSubview(logoutButton)
        
        // MARK: - Constraints
        
        NSLayoutConstraint.activate([
            // Profile Image
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            // Login Name Label
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Description Label
            descriptionLabel.leadingAnchor.constraint(equalTo: loginNameLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: loginNameLabel.trailingAnchor),
            
            // Logout Button
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
        ])
    }
    
    // MARK: - ProfileViewProtocol
    
    func displayProfile(_ profile: Profile) {
            nameLabel.text = profile.name
            loginNameLabel.text = profile.loginName
            if let bio = profile.bio, !bio.isEmpty {
                descriptionLabel.text = bio
                descriptionLabel.isHidden = false
            } else {
                descriptionLabel.text = ""
                descriptionLabel.isHidden = true
            }
        }
    
    func displayAvatar(with url: URL) {
        print("🖼️ [ProfileViewController] displayAvatar вызван с URL: \(url)")
            profileImageView.kf.setImage(with: url, placeholder: UIImage(named: "tab_profile_active"))
        }
    
    func showError(_ message: String) {
            // показываем алерт
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
    func showLogoutConfirmation() {
            let alert = UIAlertController(
                title: "Пока, пока!",
                message: "Уверены, что хотите выйти?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Да", style: .destructive) { _ in
                ProfileLogoutService.shared.logout()
            })
            alert.addAction(UIAlertAction(title: "Нет", style: .cancel))
            present(alert, animated: true)
        }
    
    @objc private func didTapLogoutButton() {
            presenter?.didTapLogout()
        }
}
