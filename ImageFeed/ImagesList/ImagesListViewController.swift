import UIKit
import Kingfisher

// MARK: - Protocol
protocol ImagesListViewProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func displayPhotos(_ photos: [Photo])
    func updatePhoto(at index: Int, with photo: Photo)
}

final class ImagesListViewController: UIViewController, ImagesListViewProtocol {
    
    // MARK: - Constants
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    //    private let imagesListService = ImagesListService.shared
    
    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Properties
    var presenter: ImagesListPresenterProtocol?
    private var photos: [Photo] = []
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        presenter?.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            let photo = photos[indexPath.row]
            viewController.imageURL = photo.largeImageURLString
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
        print("✅ [ViewController] Презентер внедрён")
    }
    
    // MARK: - Setup UI
    
    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.separatorStyle = .none
    }
    
    // MARK: - ImagesListViewProtocol
    
    func displayPhotos(_ photos: [Photo]) {
        self.photos = photos
        tableView.reloadData()
    }
    
    func updatePhoto(at index: Int, with photo: Photo) {
        photos[index] = photo
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        print("🔄 [ViewController] updatePhoto вызван для индекса \(index)")
    }
    
    // MARK: - Private Methods (конфигурация ячейки)
    
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        
        let photo = photos[indexPath.row]
        
        // Загружаем миниатюру через Kingfisher
        cell.cellImage.kf.setImage(
            with: URL(string: photo.thumbImageURLString),
            placeholder: UIImage(named: "placeholder")
        )
        
        // Форматируем дату
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }
        
        // Настраиваем лайк
        let likeImage = photo.isLiked
        ? UIImage(named: "like_button_on")
        : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
        cell.likeButton.accessibilityValue = photo.isLiked ? "liked" : "unliked"
        
        // Сохраняем id фото для обработки лайка
        cell.likeButton.tag = indexPath.row
        cell.likeButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
    }
    
    @objc private func likeButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let photo = photos[index]
        let isLiked = photo.isLiked
        let newIsLiked = !isLiked
        
        // Блокируем кнопку, чтобы предотвратить повторные нажатия
        sender.isEnabled = false
        
        // Оптимистично обновляем UI (мгновенно)
        let newImage = newIsLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        sender.setImage(newImage, for: .normal)
        sender.tintColor = newIsLiked ? .red : .white
        sender.accessibilityValue = newIsLiked ? "liked" : "unliked"
        
        // Анимация при нажатии
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                sender.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.2) {
                sender.transform = .identity
            }
        })
        
        // Вызываем презентер для отправки запроса
        presenter?.didTapLike(at: index) { [weak self] result in
            // Разблокируем кнопку после завершения
            sender.isEnabled = true

            switch result {
            case .success:
                // Всё хорошо — перезагружаем ячейку, чтобы обновить состояние
                let indexPath = IndexPath(row: index, section: 0)
            case .failure:
                // Откат UI при ошибке
                print("❌ [ImagesListViewController] Ошибка изменения лайка")
                let fallbackImage = photo.isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
                sender.setImage(fallbackImage, for: .normal)
                sender.tintColor = photo.isLiked ? .red : .white
                sender.accessibilityValue = photo.isLiked ? "liked" : "unliked"
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Проверяем, последняя ли это ячейка
        if indexPath.row + 1 == photos.count {
            presenter?.fetchNextPage()
        }
    }
}
    
// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: cell, with: indexPath)
        
        return cell
    }
}
