import Foundation

final class NetworkClient {
    static let shared = NetworkClient()
    private init(){
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private let decoder = JSONDecoder()

    /// Detects the common Unsplash rate-limit body (plain text)
    private func isPlainTextRateLimit(_ data: Data) -> Bool {
        guard let s = String(data: data, encoding: .utf8) else { return false }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.caseInsensitiveCompare("Rate Limit Exceeded") == .orderedSame
            || trimmed.lowercased().contains("rate limit exceeded")
    }
    
    func fetch(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let task = URLSession.shared.data(for: request, completion: completion)
        task.resume()
        return task
    }
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        print("📡 [NetworkClient] Starting objectTask with request: \(request.url?.absoluteString ?? "nil URL")")
        let task = URLSession.shared.data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                // Early-detect plain-text rate limit to avoid JSON decoding crashes
                if self.isPlainTextRateLimit(data) {
                    let err = NSError(domain: "RateLimit", code: 429,
                                       userInfo: [NSLocalizedDescriptionKey: "Rate Limit Exceeded"]) as Error
                    print("⚠️ [NetworkClient] Rate limit detected (plain text body)")
                    completion(.failure(err))
                    return
                }
                do {
                    let decoded = try self.decoder.decode(T.self, from: data)
                    print("✅ [NetworkClient] Decoded object: \(decoded)")
                    completion(.success(decoded))
                } catch {
                    print("❌ [NetworkClient] Decoding failed: \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "")")
                    print("📦 [NetworkClient] Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                print("❌ [NetworkClient] dataTask failed with error: \(error)")
                completion(.failure(error))
            }
        }
        return task
    }
}


