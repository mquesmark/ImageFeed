import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    
    private let dataStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    
    private var lastCode: String?
    
    private(set) var authToken: String? {
        get {
            dataStorage.token
        }
        set {
            dataStorage.token = newValue
        }
    }
    
    private init() {}
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard lastCode != code else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastCode = code

        print("✅ [OAuth2Service] Received code: \(code)")
        guard
            let request = makeOAuthTokenRequest(code: code)
        else {
            print("❌ [OAuth2Service] Failed to create request")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        print("✅ [OAuth2Service] Token request URL: \(request.url?.absoluteString ?? "нет url")")
        if let body = request.httpBody {
            print("✅ [OAuth2Service] Request body: \(String(data: body, encoding: .utf8) ?? "не удалось декодировать")")
        }

        task = NetworkClient.shared.objectTask(for: request){ [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            print("📤 [OAuth2Service] Started objectTask for token fetch")
            switch result {
            case .success(let decoded):
                self?.authToken = decoded.accessToken
                print("💾 [OAuth2Service] Saved authToken: \(decoded.accessToken)")
                completion(.success(decoded.accessToken))
            case .failure(let error):
                print("❌ [OAuth2Service] Failed to fetch token: \(error)")
                completion(.failure(AuthServiceError.networkError(error)))
            }
            self?.task = nil
            self?.lastCode = nil
        }
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard
            var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token")
        else {
            assertionFailure("Failed to create URL")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        print("🔧 [OAuth2Service] URLComponents: \(urlComponents)")

        guard let authTokenUrl = urlComponents.url else {
            print("❌ [OAuth2Service] Failed to create token URL")
            return nil
        }

        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        return request
    }
}

private struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

enum AuthServiceError: Error {
    case invalidRequest
    case networkError(Error)
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
