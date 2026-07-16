import Foundation

// MARK: - PhotoResult (для декодинга JSON-ответа)
struct PhotoResult: Decodable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult
    
    enum CodingKeys: String, CodingKey {
        case id
        case width
        case height
        case createdAt = "created_at"
        case description
        case likedByUser = "liked_by_user"
        case urls
    }
}

// MARK: - UrlsResult (вложенный объект)
struct UrlsResult: Decodable {
    let thumb: String
    let full: String
}
