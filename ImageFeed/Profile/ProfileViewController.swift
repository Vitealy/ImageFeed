import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private var profileImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    // MARK: - Properties
    
    private let profileService = ProfileService.shared
    private let tokenStorage = OAuth2TokenStorage()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupProfileElements()
        loadProfile()
    }
    
    private func setupProfileElements() {
        
        // MARK: - Avatar image
        
        profileImageView = UIImageView()
        profileImageView = UIImageView(image: UIImage(named: "Avatar"))
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 35
        profileImageView.layer.masksToBounds = true
        view.addSubview(profileImageView)
        
        // MARK: - Name Label
        
        nameLabel = UILabel()
        nameLabel.text = "Загрузка..."
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = .ypWhite
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        // MARK: - Login Name Label
        
        loginNameLabel = UILabel()
        loginNameLabel.text = "Загрузка..."
        loginNameLabel.font  = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = .ypGray
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        // MARK: - Description Label
        
        descriptionLabel = UILabel()
        descriptionLabel.text = "Загрузка..."
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // MARK: - Logout Button
        
        logoutButton = UIButton(type: .system)
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
    
    // MARK: - Private Methods
    private func loadProfile() {
        guard let token = tokenStorage.token else {
            print("❌ [ProfileViewController] Токен не найден")
            return
        }
        
        print("🔄 [ProfileViewController] Начинаем загрузку профиля...")
        
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                print("✅ [ProfileViewController] Профиль успешно загружен")
                self.updateUI(with: profile)
                
            case .failure(let error):
                print("❌ [ProfileViewController] Ошибка загрузки профиля: \(error.localizedDescription)")
                self.showErrorAlert(message: "Не удалось загрузить профиль")
            }
        }
    }
    
    private func updateUI(with profile: Profile) {
        guard let nameLabel = nameLabel,
              let loginNameLabel = loginNameLabel,
              let descriptionLabel = descriptionLabel else {
            print("❌ [ProfileViewController] UI-элементы не инициализированы")
            return
        }
        
        DispatchQueue.main.async {
            self.nameLabel.text = profile.name
            self.loginNameLabel.text = profile.loginName
            self.descriptionLabel.text = profile.bio ?? "Описание отсутствует"
            
            if let avatarURL = profile.avatarURL {
                self.loadAvatar(from: avatarURL)
            }
        }
    }
    
    private func loadAvatar(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ [ProfileViewController] Невалидный URL аватара")
            return
        }
        
        // Загружаем изображение в фоновом потоке
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func didTapLogoutButton() {
        print("Выход из профиля")
    }
}
