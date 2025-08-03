import WebKit

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

extension URLSession {
    func data(for request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        print("📤 [URLSession] Sending request to: \(request.url?.absoluteString ?? "no url")")

        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [URLSession] Request failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("❌ [URLSession] No data in response.")
                completion(.failure(NetworkError.invalidRequest))
                return
            }

            print("✅ [URLSession] Received data: \(String(data: data, encoding: .utf8) ?? "unreadable")")
            completion(.success(data))
        }

        task.resume()
        return task
    }
}
