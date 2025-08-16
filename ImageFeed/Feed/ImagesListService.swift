import UIKit

final class ImagesListService {
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let didChangeLikeNotification = Notification.Name("ImagesListServiceDidChangeLike")
    static let shared = ImagesListService()
    private init() {}
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private var likeTask: URLSessionTask?
    
    func fetchPhotosNextPage() {
        guard task == nil else { return }
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let request = makeURLRequest(for: nextPage) else {
            print("Failed to create URLRequest")
            return
        }
        task = NetworkClient.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            switch result {
            case .success(let items):
                let newPhotos: [Photo] = items.map { photo in
                    Photo(
                        id: photo.id,
                        size: CGSize(width: photo.width, height: photo.height),
                        createdAt: photo.createdAt,
                        welcomeDescription: photo.description,
                        thumbImageURL: photo.urls.thumb,
                        largeImageURL: photo.urls.full,
                        isLiked: photo.likedByUser
                    )
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let existingIDs = Set(self.photos.map { $0.id })
                    let uniqueNew = newPhotos.filter { !existingIDs.contains($0.id) }

                    self.photos.append(contentsOf: uniqueNew)
                    self.lastLoadedPage = nextPage

                    if !uniqueNew.isEmpty {
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self
                        )
                    }
                }
            case .failure(let error):
                print("Failed to fetch photos: \(error)")
            }
            self?.task = nil
        }
    }
    func changeLike(photoId: String, isLiked: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard likeTask == nil,
            let request = makeURLRequest(forId: photoId, isLiked: isLiked) else {
            print("Like Task already in progress / Or error in making URLRequest for changing like")
            completion(.failure(ImagesListServiceError.invalidRequest))
            return
        }
        
       likeTask = NetworkClient.shared.objectTask(for: request) { [weak self] (result: Result<LikeResponse, Error>) in
            switch result {
            case .success(let likeResponse):
                if let index = self?.photos.firstIndex(where: {$0.id == photoId}) {
                    self?.photos[index].isLiked = likeResponse.photo.likedByUser
                    NotificationCenter.default.post(name: ImagesListService.didChangeLikeNotification, object: self, userInfo: ["photoId": photoId])
                }
                completion(.success(()))
            case .failure(let error):
            print("Error in changing like: \(error)")
                completion(.failure(error))
            }
           self?.likeTask = nil
        }
    }

        
    // MARK: - Private methods
    
    private func makeURLRequest(for page: Int) -> URLRequest? {
        guard page >= 1,
              let token = OAuth2TokenStorage.shared.token,
              let url = URL(string: "https://api.unsplash.com/photos?page=\(page)&per_page=30") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func makeURLRequest(forId id: String, isLiked: Bool) -> URLRequest? {
        guard let token = OAuth2TokenStorage.shared.token,
              let url = URL(string: "https://api.unsplash.com/photos/\(id)/like") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLiked ? "DELETE" : "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}



struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
}

struct PhotoResult: Decodable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: Date?
    let description: String?
    let urls: Urls
    let likedByUser: Bool
    
    struct Urls: Decodable {
        let thumb: String
        let full: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case width
        case height
        case createdAt = "created_at"
        case description
        case urls
        case likedByUser = "liked_by_user"
    }
    
}

enum ImagesListServiceError: Error {
    case invalidURL
    case decodingFailed
    case invalidRequest
}

struct LikeResponse: Decodable {
    let photo: PhotoResult
}
