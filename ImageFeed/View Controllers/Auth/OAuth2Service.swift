import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    
    private let dataStorage = OAuth2TokenStorage()
    private let urlSession = URLSession.shared
    
    private var task: URLSessionTask?
    
    private var lastCode: String?
    
    private(set) var authToken: String? {
        get {
            return dataStorage.token
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

        print("Получен код: \(code)")
        guard
            let request = makeOAuthTokenRequest(code: code)
        else {
            print("Request failed")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        print("URL запроса токена: \(request.url?.absoluteString ?? "нет url")")
        if let body = request.httpBody {
            print("Тело запроса: \(String(data: body, encoding: .utf8) ?? "не удалось декодировать")")
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async { //12
                NetworkClient.shared.fetch(request: request) { result in
                    switch result {
                    case .success(let data):
                        print("Сырые данные ответа: \(String(data: data, encoding: .utf8) ?? "не удалось декодировать")")
                        do {
                            let decoded = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                            self?.authToken = decoded.accessToken
                            completion(.success(decoded.accessToken))
                        } catch {
                            print("JSON decoding failed: \(error)")
                            completion(.failure(AuthServiceError.networkError(error)))
                        }
                    case .failure(let error):
                        print("Network error: \(error)")
                        completion(.failure(error))
                    }
                }
                self?.task = nil // 14
                self?.lastCode = nil // 15
            }
        }
        self.task = task // 16
        task.resume() // 17
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
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

        guard let authTokenUrl = urlComponents.url else {
            print("URL failed")
            return nil
        }

        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
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
