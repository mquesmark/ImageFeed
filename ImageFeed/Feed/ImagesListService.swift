import UIKit
protocol ImagesListServiceProtocol {
    var photos: [Photo] { get set }
    func changeLike(photoId: String, isLiked: Bool, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchPhotosNextPage()
}
final class ImagesListService: ImagesListServiceProtocol {
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let shared = ImagesListService()
    private init() {}
    
    var photos: [Photo] = []
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
            guard let self else { return }

            switch result {
            case .success(let items):
                self.handlePhotosResponse(items, nextPage: nextPage)
            case .failure(let error):
                self.handlePhotosError(error, page: nextPage)
            }
            self.task = nil
        }
    }
    
    func clearFeed() {
        photos = []
        lastLoadedPage = 0
    }
    
    func changeLike(photoId: String, isLiked: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard likeTask == nil,
            let request = makeURLRequest(forId: photoId, isLiked: isLiked) else {
            print("[changeLike ImagesListService]: invalidRequest photoId=\(photoId) isLiked=\(isLiked)")
            completion(.failure(ImagesListServiceError.invalidRequest))
            return
        }
        
       likeTask = NetworkClient.shared.objectTask(for: request) { [weak self] (result: Result<LikeResponse, Error>) in
            switch result {
            case .success(let response):
                guard let self else { return }
                if let index = self.photos.firstIndex(where: { $0.id == response.photo.id }) {
                    self.photos[index].isLiked = response.photo.likedByUser
                }
                completion(.success(()))
            case .failure(let error):
            print("[changeLike ImagesListService]: \(error) photoId=\(photoId) isLiked=\(isLiked)")
                completion(.failure(error))
            }
           self?.likeTask = nil
        }
    }

        
    // MARK: - Private methods

    private func handlePhotosResponse(_ items: [PhotoResult], nextPage: Int) {
        let newPhotos = mapPhotoResults(items)
        appendUnique(newPhotos, nextPage: nextPage)
    }

    private func mapPhotoResults(_ items: [PhotoResult]) -> [Photo] {
        return items.map { photo in
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
    }

    private func appendUnique(_ newPhotos: [Photo], nextPage: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let existingIDs = Set(self.photos.map { $0.id })
            let uniqueNew = newPhotos.filter { !existingIDs.contains($0.id) }

            self.photos.append(contentsOf: uniqueNew)
            self.lastLoadedPage = nextPage
            self.postDidChangeIfNeeded(uniqueNew)
        }
    }

    private func postDidChangeIfNeeded(_ newPhotos: [Photo]) {
        guard !newPhotos.isEmpty else { return }
        NotificationCenter.default.post(
            name: ImagesListService.didChangeNotification,
            object: self
        )
    }

    private func handlePhotosError(_ error: Error, page: Int) {
        print("[fetchPhotosNextPage ImagesListService]: \(error) page=\(page)")
    }
    
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


// MARK: - Models
struct PhotoResult: Decodable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: Date?
    let description: String?
    let urls: UrlsResult
    let likedByUser: Bool
    
    struct UrlsResult: Decodable {
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
