import XCTest

final class ImageFeed_UITests: XCTestCase {
    private let app = XCUIApplication()
    private let loginData = LoginData()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("UITEST_DISABLE_PAGINATION")
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
        
        if app.toolbars.buttons["Done"].waitForExistence(timeout: 2) {
            app.toolbars.buttons["Done"].tap()
        } else if app.keyboards.buttons["Done"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Done"].tap()
        }
        
        
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        loginButton.tap()
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables
        
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        waitToAppear(cell)
        
        cell.swipeUp()
        sleep(1)
        
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        let screenFrame = app.windows.firstMatch.frame
        var likeButton = cellToLike.buttons["likeButton"]
        waitToAppear(likeButton)

        // Обработка ситуации, когда фото улетело за границу экрана и XCTest не может тапнуть по лайку (возвращаемся в верх таблицы, чтобы кнопка лайка снова была доступна к нажатию):
        while !screenFrame.intersects(likeButton.frame) {
            tablesQuery.element.swipeDown()
            sleep(1)

            likeButton = cellToLike.buttons["likeButton"]
            waitToAppear(likeButton)
        }
        
        sleep(2)

        likeButton.tap()
        
        sleep(5)
        
        let dislikeButton = cellToLike.buttons["likeButton"]

        waitToAppear(dislikeButton, timeout: 5)
        sleep(2)
        dislikeButton.tap()
        sleep(5)
        
        let cellImage = cellToLike.images.firstMatch
    
        if cellImage.exists && cellImage.isHittable {
            cellImage.tap()
        } else {
            XCTFail("Failed to find cell image")
        }
        
        sleep(2)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        
        image.pinch(withScale: 3, velocity: 1)
        sleep(1)
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
        
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 10))
    }
    
    
    // MARK: - Helpers
    
    struct LoginData {
        let login = ""
        let password = ""
    }
    
    private func waitToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "exists == true")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }
    
}
