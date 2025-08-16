import Foundation

final class ProfileImageService {
    
    static let shared = ProfileImageService()
    private init() {}
    
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    private(set) var avatarURL: String?
    
    private var task: URLSessionTask?
    
    struct UserResult: Codable {
        let profileImage: ProfileImage
        
        enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
        struct ProfileImage: Codable {
            let large: String // сделал не small, а large, потому что выглядит невероятно мыльно (что в том числе не соответствует макету, где фото качественно видно  в профиле)
        }
    }
    
    func fetchProfileImage(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()
        
        guard let request = makeURLRequest(for: username) else {
            print("❌ [ProfileImageService] Failed to create avatar URL request")
            return
        }
        
        task = NetworkClient.shared.objectTask(for: request) {
            [weak self] (result: Result<UserResult, Error>) in
            switch result {
            case .success(let userResult):
                let imageURL = userResult.profileImage.large
                self?.avatarURL = imageURL
                NotificationCenter.default.post(name: ProfileImageService.didChangeNotification, object: self,
                                                userInfo: ["URL": imageURL])
                completion(.success(imageURL))
                
            case .failure(let error):
                print("❌ [ProfileImageService] Failed to fetch avatar URL: \(error)")
                completion(.failure(error))
            }
            self?.task = nil
        }
    }
    
    
    
    
    // MARK: Private methods
    private func makeURLRequest(for username: String) -> URLRequest? {
        
        guard let token = OAuth2TokenStorage.shared.token else {
            return nil
        }
        
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }
        var request = URLRequest (url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
