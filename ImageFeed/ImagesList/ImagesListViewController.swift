import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    
    // MARK: - Constants
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesListService = ImagesListService.shared
    
    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Properties
    private var imagesListServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        // Подписываемся на нотификацию об обновлении ленты
        imagesListServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ImagesListService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                // Проверяем, есть ли userInfo с photoId
                if let photoId = notification.userInfo?["photoId"] as? String,
                   let index = self?.imagesListService.photos.firstIndex(where: { $0.id == photoId }) {
                    // Обновляем только одну ячейку
                    let indexPath = IndexPath(row: index, section: 0)
                    self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                } else {
                    // Иначе обновляем всю таблицу (новая страница)
                    self?.updateTableViewAnimated()
                }
            }
        
        // Загружаем первую страницу
        imagesListService.fetchPhotosNextPage()
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
            
            let photo = imagesListService.photos[indexPath.row]
            viewController.imageURL = photo.largeImageURL
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Setup UI
    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.separatorStyle = .none
    }
    
    // MARK: - Private Methods
        private func updateTableViewAnimated() {
            let oldCount = tableView.numberOfRows(inSection: 0)
            let newCount = imagesListService.photos.count
            
            if oldCount != newCount {
                tableView.performBatchUpdates {
                    let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                    tableView.insertRows(at: indexPaths, with: .automatic)
                } completion: { _ in }
            }
        }
    
}

// MARK: - Private Methods (конфигурация ячейки)
private extension ImagesListViewController {
    
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        
        let photo = imagesListService.photos[indexPath.row]
        
        // Загружаем миниатюру через Kingfisher
                cell.cellImage.kf.setImage(
                    with: URL(string: photo.thumbImageURL),
                    placeholder: UIImage(named: "placeholder") 
                )
        
        // Форматируем дату
                if let createdAt = photo.createdAt {
                    cell.dateLabel.text = DateFormatter.localizedString(
                        from: createdAt,
                        dateStyle: .long,
                        timeStyle: .none
                    )
                } else {
                    cell.dateLabel.text = ""
                }
        
        // Настраиваем лайк
        let likeImage = photo.isLiked
        ? UIImage(named: "like_button_on")
        : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
        
        // Сохраняем id фото для обработки лайка
        cell.likeButton.tag = indexPath.row
        cell.likeButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
    }
    
    @objc private func likeButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let photo = imagesListService.photos[index]
        let isLiked = photo.isLiked
        
        // Анимация при нажатии
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                sender.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.2) {
                sender.transform = .identity
            }
        })
        
        imagesListService.changeLike(photoId: photo.id, isLiked: isLiked) { [weak self] result in
            
            switch result {
            case .success(_):
               
                DispatchQueue.main.async {
                    let indexPath = IndexPath(row: index, section: 0)
                    self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                
            case .failure(let error):
                print("❌ [ImagesListViewController] Ошибка изменения лайка: \(error.localizedDescription)")
                
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
        
        let photo = imagesListService.photos[indexPath.row]
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            // Проверяем, последняя ли это ячейка
            if indexPath.row + 1 == imagesListService.photos.count {
                imagesListService.fetchPhotosNextPage()
            }
        }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagesListService.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: cell, with: indexPath)
        
        return cell
    }
    
}
