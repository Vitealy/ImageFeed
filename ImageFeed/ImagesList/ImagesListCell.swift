import UIKit

final class ImagesListCell: UITableViewCell {
    
    static let reuseIdentifier: String = "ImagesListCell"
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    // Градиентный слой для подложки даты
    private var gradientView: UIView?
    private var gradientLayer: CAGradientLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDateGradient()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientFrame()
    }
    
    private func setupDateGradient() {
        
        dateLabel.backgroundColor = .clear
        
        // Удаляем старый gradientView, если был
        gradientView?.removeFromSuperview()
        
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.backgroundColor = .clear
        contentView.addSubview(gradientView)
        
        NSLayoutConstraint.activate([
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Создаем градиентный слой
        let gradient = CAGradientLayer()
        
        gradient.colors = [
            UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 0.7).cgColor,  // #1A1B22 с прозрачностью 70% (сверху)
            UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 0.0).cgColor   // #1A1B22 полностью прозрачный (снизу)
        ]
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)  // начинаем сверху
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)    // заканчиваем снизу
        gradient.frame = gradientView.bounds
        
        gradient.cornerRadius = 4
        
        gradientView.layer.insertSublayer(gradient, at: 0)
        
        contentView.sendSubviewToBack(gradientView)
        contentView.bringSubviewToFront(dateLabel)
        self.gradientView = gradientView
        self.gradientLayer = gradient
    }
    
    private func updateGradientFrame() {
        gradientLayer?.frame = gradientView?.bounds ?? .zero
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        gradientLayer?.removeFromSuperlayer()
        gradientView?.removeFromSuperview()
        setupDateGradient()
    }
}
