import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    // MARK: - Properties
    var imageURL: String? {
        didSet {
            if isViewLoaded {
                loadImage()
            }
        }
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        loadImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerImageIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func loadImage() {
        guard let urlString = imageURL, let url = URL(string: urlString) else {
            // Если URL нет — показать плейсхолдер
            imageView.image = UIImage(named: "placeholder")
            return
        }
        
        // ✅ Показываем HUD перед началом загрузки
        UIBlockingProgressHUD.show()
        
        // ✅ Загружаем полноразмерное изображение через Kingfisher
        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder")
        ) { [weak self] result in
            // ✅ Скрываем HUD после завершения загрузки (всегда)
            UIBlockingProgressHUD.dismiss()
            switch result {
            case .success(let value):
                // После загрузки настраиваем скролл и центрирование
                self?.imageView.frame.size = value.image.size
                self?.rescaleAndCenterImageInScrollView(image: value.image)
            case .failure(let error):
                print("❌ [SingleImageViewController] Ошибка загрузки изображения: \(error.localizedDescription)")
            }
        }
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        centerImageIfNeeded()
    }
    
    private func centerImageIfNeeded() {
        guard imageView.image != nil else { return }
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size
        
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)
        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    // MARK: - IBActions
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageIfNeeded()
    }
    
}
