import XCTest

final class ImageFeed_UITests: XCTestCase {
    private let app = XCUIApplication()
    private let loginData = LoginData()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testAuth() throws {
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 20))
        app.buttons["Authenticate"].tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
        
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        loginTextField.tap()
        loginTextField.typeText(loginData.login)
        if app.toolbars.buttons["Next"].exists {
            app.toolbars.buttons["Next"].tap()
        } else {
            XCTFail()
        }
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        
        passwordTextField.tap()
        passwordTextField.typeText(loginData.password)
        sleep(3)
        if app.toolbars.buttons["Done"].waitForExistence(timeout: 5) {
            app.toolbars.buttons["Done"].tap()
        }
        
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables
        XCTAssertTrue(tablesQuery.element.waitForExistence(timeout: 20))
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        cell.swipeUp()
        
        sleep(2)
        
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        
        let likeButton = cellToLike.buttons["likeButton"]
        likeButton.tap()
        
        sleep(5)
        
        likeButton.tap()
        
        sleep(5)
        let cellImage = cellToLike.images.firstMatch
        if cellImage.exists && cellImage.isHittable {
            cellImage.tap()
        } else {
            let cellCenter = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            cellCenter.tap()
        }
        
        sleep(2)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 10))
        
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)
        
        let backButton = app.buttons["backButton"]
        backButton.tap()
        
    }
    
    func testProfile() throws {
        let tablesQuery = app.tables
        XCTAssertTrue(tablesQuery.element.waitForExistence(timeout: 20))
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["Максим Гвазава"].exists)
        XCTAssertTrue(app.staticTexts["@mquesmark"].exists)
        
        app.buttons["exitButton"].tap()
        
        app.alerts["confirmLogoutAlert"].scrollViews.otherElements.buttons["Да"].tap()
        
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 20))
    }
}

// MARK: - Helpers

struct LoginData {
    let login = "maximgv@icloud.com"
    let password = "dontStealMyPassword19122002"
}
