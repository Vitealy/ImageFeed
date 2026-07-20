import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private var profileImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    // MARK: - Properties
    
    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupProfileElements()
        updateUIWithSavedProfile()
        
        // ✅ ПОДПИСЫВАЕМСЯ НА НОТИФИКАЦИЮ
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                // Когда приходит нотификация — обновляем аватарку
                self.updateAvatar()
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIWithSavedProfile()
    }
    
    deinit {
        // ✅ УДАЛЯЕМ ОБСЕРВЕР ПРИ УНИЧТОЖЕНИИ КОНТРОЛЛЕРА
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Setup UI
    private func setupProfileElements() {
        
        // MARK: - Avatar image
        
        profileImageView = UIImageView()
        profileImageView = UIImageView(image: UIImage(named: "tab_profile_active"))
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
    
    private func updateUIWithSavedProfile() {
        guard let profile = profileService.profile else {
            print("ℹ️ [ProfileViewController] Профиль ещё не загружен")
            return
        }
        
        updateUI(with: profile)
    }
    
    private func updateUI(with profile: Profile) {
        guard nameLabel != nil,
              loginNameLabel != nil,
              descriptionLabel != nil else {
            print("❌ [ProfileViewController] UI-элементы не инициализированы")
            return
        }
        
            self.nameLabel.text = profile.name
            self.loginNameLabel.text = profile.loginName
            self.descriptionLabel.text = profile.bio ?? "Описание отсутствует"
            
            self.updateAvatar()
    }
    
    private func updateAvatar() {
        guard let avatarURL = ProfileImageService.shared.avatarURL,
              let url = URL(string: avatarURL) else {
            // Если аватарки нет — ставим дефолтную
            self.profileImageView.image = UIImage(named: "tab_profile_active")
            return
        }
        loadAvatar(from: url)
    }
    
    private func loadAvatar(from url: URL) {

        profileImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "tab_profile_active"),
            options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ]
        ) { [weak self] result in
            switch result {
            case .success(let value):
                print("✅ [ProfileViewController] Аватарка загружена: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("❌ [ProfileViewController] Ошибка загрузки аватарки: \(error.localizedDescription)")
                // В случае ошибки показываем дефолтную аватарку
                self?.profileImageView.image = UIImage(named: "tab_profile_active")
            }
        }
    }
    
    @objc private func didTapLogoutButton() {
        
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        // Кнопка "Да" — выполняем выход
        let yesAction = UIAlertAction(title: "Да", style: .destructive) { _ in
            print("❌🔚🏃🚪 [ProfileViewController] Выход из профиля")
            ProfileLogoutService.shared.logout()
        }
        
        // Кнопка "Нет" — просто закрываем алерт
        let noAction = UIAlertAction(title: "Нет", style: .cancel)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        // Показываем алерт
        present(alert, animated: true, completion: nil)
        
//        print("❌🔚🏃🚪 [ProfileViewController] Выход из профиля")
//        ProfileLogoutService.shared.logout()
    }
}
