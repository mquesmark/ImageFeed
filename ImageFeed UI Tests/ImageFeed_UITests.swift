import XCTest

final class ImageFeed_UITests: XCTestCase {
    private let app = XCUIApplication()
    private let loginData = LoginData()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        print("🚀 Приложение запущено")
    }
    
    func testAuth() throws {
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 20))
        print("✅ Кнопка Authenticate появилась")
        app.buttons["Authenticate"].tap()
        print("👆 Нажата кнопка Authenticate")
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
        print("✅ Веб-вью загрузилась")
        
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        print("✅ Текстовое поле для логина найдено")
        loginTextField.tap()
        print("👆 Тап по полю логина")
        loginTextField.typeText(loginData.login)
        print("📩 Введен логин")
        if app.toolbars.buttons["Next"].exists {
            app.toolbars.buttons["Next"].tap()
            print("👆 Нажата кнопка Next на тулбаре")
        } else {
            print("⚠️ Кнопка Next не найдена")
            XCTFail()
        }
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        print("✅ Поле для пароля найдено")
        
        passwordTextField.tap()
        print("👆 Тап по полю пароля")
        passwordTextField.typeText(loginData.password)
        print("🔐 Введен пароль")
        sleep(3)
        
        if app.toolbars.buttons["Done"].waitForExistence(timeout: 2) {
            app.toolbars.buttons["Done"].tap()
            print("👆 Нажата кнопка Done на тулбаре")
        } else if app.keyboards.buttons["Done"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Done"].tap()
            print("👆 Нажата кнопка Done на клавиатуре")
        } else {
            print("⚠️ Кнопка Done не найдена")
        }
        
        
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        print("✅ Кнопка Login появилась")
        loginButton.tap()
        print("👆 Нажата кнопка Login")
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        print("✅ Первая ячейка таблицы появилась после авторизации")
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables
        
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        waitToAppear(cell)
        
        cell.swipeUp(velocity: .slow)
        
        gentlePause(for: 2)
        
        let anotherCell = tablesQuery.children(matching: .cell).element(boundBy: 2)
        waitToAppear(anotherCell)
        anotherCell.swipeDown()
        
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        waitToAppear(cellToLike)
        
        let likeButton = cellToLike.buttons["likeButton"]
        waitToAppear(likeButton)
        
        
        likeButton.tap()
        
        
        gentlePause(for: 10)
        
        let dislikeButton = cellToLike.buttons["likeButton"]
        waitToAppear(dislikeButton, timeout: 10)
        dislikeButton.tap()
        
        gentlePause(for: 10)
        
        let cellImage = cellToLike.images.firstMatch
        print("📸 Проверяем доступность изображения для открытия")
        if cellImage.exists && cellImage.isHittable {
            print("📸 Тап по изображению")
            cellImage.tap()
        } else {
            print("❌ Не удалось тапнуть по изображению")
            XCTFail()
        }
        
        gentlePause(for: 2)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 10))
        print("✅ Изображение открыто")
        
        print("🔍 Увеличиваем изображение")
        image.pinch(withScale: 3, velocity: 1)
        print("🔎 Уменьшаем изображение")
        image.pinch(withScale: 0.5, velocity: -1)
        
        let backButton = app.buttons["backButton"]
        print("🔙 Возврат назад")
        backButton.tap()
        print("👈 Вернулись назад")
    }
    
    
    func testProfile() throws {
        let tablesQuery = app.tables
        XCTAssertTrue(tablesQuery.element.waitForExistence(timeout: 20))
        print("✅ Таблица появилась на главном экране")
        app.tabBars.buttons.element(boundBy: 1).tap()
        print("👆 Перешли на вкладку Профиль")
        XCTAssertTrue(app.staticTexts["Максим Гвазава"].exists)
        XCTAssertTrue(app.staticTexts["@mquesmark"].exists)
        print("✅ Имя и логин пользователя отображаются")
        
        app.buttons["exitButton"].tap()
        print("👆 Нажата кнопка выхода из профиля")
        
        app.alerts["confirmLogoutAlert"].scrollViews.otherElements.buttons["Да"].tap()
        print("👆 Подтвержден выход из профиля")
        
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 20))
        print("✅ Появился экран авторизации")
    }
    
    
    // MARK: - Helpers
    
    struct LoginData {
        let login = "maximgv@icloud.com"
        let password = "dontStealMyPassword19122002" // Я случайно запушил на github свой пароль, но так как он все равно временный и только для unsplash, нигде не больше не используется, поэтому пусть для удобства ревью остается. Аккаунт мне там если что не жалко))
    }
    private func waitToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "exists == true")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout) { _ in
            print("Element \(element) appeared. Yay")
        }
    }
    
    private func gentlePause(for seconds: TimeInterval) {
        let expectation = expectation(description: "Gentle pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 1)
    }
}
