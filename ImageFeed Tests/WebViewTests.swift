@testable import ImageFeed
import XCTest

final class WebViewTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() {
        // Given
        let webVC = WebViewViewController()
        let presenter = WebViewPresenterSpy()
        webVC.presenter = presenter
        presenter.view = webVC
        
        // When
        _ = webVC.view
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    func testPresenterCallsLoadRequest() {
        // Given
        let webVC = WebViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        presenter.view = webVC
        webVC.presenter = presenter
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(webVC.loadDidCalled)
    }
    
    func testProgressVisibleWhenLessThenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let values: [Float] = [0.01, 0.5, 0.99]
        
        for value in values {
            // When
            let shouldHideProgress = presenter.shouldHideProgress(for: value)
            // Then
            XCTAssertFalse(shouldHideProgress)
        }
    }
    
    func testProgressHiddenWhenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: 1.0)
        // Then
        XCTAssertTrue(shouldHideProgress)
    }
    
    func testAuthHelperAuthURL() {
        // Given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        let requestedComponents: [String] = [configuration.authURLString, configuration.accessKey, configuration.redirectURI, configuration.redirectURI, configuration.accessScope]
        // When
        let url = authHelper.authURL()
        
        guard let urlString = url?.absoluteString else {
            XCTFail("Auth URL is nil")
            return
        }
        
        // Then
        for component in requestedComponents {
            XCTAssertTrue(urlString.contains(component))
        }
        XCTAssertTrue(urlString.contains("code"))
    }
    
    func testCodeFromURL() {
        
        // Given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [ URLQueryItem(name: "code", value: "test code") ]
        let url = urlComponents.url!
        let authHelper = AuthHelper()

        // When
        let code = authHelper.code(from: url)
        
        // Then
        
        XCTAssertEqual(code, "test code")
    }
    
    
    
    
    
    // MARK: - Helpers
}
final class WebViewPresenterSpy: WebViewPresenterProtocol {
    
    var viewDidLoadCalled = false
    var view: WebViewViewControllerProtocol?
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didUpdateProgressValue(_ newValue: Double) {
        
    }
    
    func code(from url: URL) -> String? {
        return nil
    }
    
    
}

final class WebViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: ImageFeed.WebViewPresenterProtocol?
    var loadDidCalled = false
    
    func load(request: URLRequest) {
        loadDidCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {
        
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        
    }
    
    
}
