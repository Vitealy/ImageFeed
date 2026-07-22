import Foundation

struct PhotoLikeResult: Decodable {
    let photo: PhotoLikePhotoResult
}

struct PhotoLikePhotoResult: Decodable {
    let id: String
    let likedByUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case likedByUser = "liked_by_user"
    }
}
