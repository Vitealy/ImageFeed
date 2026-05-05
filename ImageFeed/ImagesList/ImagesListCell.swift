import UIKit

final class ImagesListCell: UITableViewCell {
    
    static let reuseIdentifier: String = "ImagesListCell"
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    // Градиентный слой для подложки даты
    private var gradientLayer: CAGradientLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDateGradient()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем frame градиента при изменении размеров
        updateGradientFrame()
    }
    
    private func setupDateGradient() {
        // Настраиваем фон label как прозрачный
        dateLabel.backgroundColor = .clear
        
        // Создаем градиентный слой
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(white: 0.15, alpha: 0.20).cgColor,
            UIColor(white: 0.15, alpha: 0.15).cgColor,
            UIColor.clear.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)  // начинаем сверху
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)    // заканчиваем снизу
        gradient.frame = dateLabel.bounds
       
        gradient.cornerRadius = 4
        
        // Вставляем градиент за текстом, но поверх изображения
        dateLabel.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    private func updateGradientFrame() {
        // Градиент должен занимать всю область label
        gradientLayer?.frame = dateLabel.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Сбрасываем градиент при переиспользовании ячейки
        gradientLayer?.removeFromSuperlayer()
        setupDateGradient()
    }
}
