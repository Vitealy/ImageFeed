import Foundation

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURLString: String
    let largeImageURLString: String
    let isLiked: Bool
}
