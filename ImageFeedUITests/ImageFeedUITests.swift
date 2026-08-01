import XCTest

final class ImageFeedUITests: XCTestCase {
    
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        
        continueAfterFailure = false
        
        app.launch()
    }
    
    // MARK: - Сценарий 1: Авторизация
    
    func testAuth() throws {
        // Нажимаем кнопку авторизации
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 3))
        authButton.tap()
        
        // Ожидаем загрузки WebView
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 10))
        
        // Поле ввода логина
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        
        loginTextField.tap()
        loginTextField.typeText("")
        webView.swipeUp()
        
        // Поле ввода пароля
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        
        passwordTextField.tap()
        passwordTextField.typeText("")
        webView.swipeUp()
        
        // Нажимаем кнопку Login
        webView.buttons["Login"].tap()
        
        // Проверяем, что открылась лента (первая ячейка таблицы)
        let cell = app.tables.cells.firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }
    
    // MARK: - Сценарий 2: Лента
    
    func testFeed() throws {
        // Ожидаем загрузки ленты
        let table = app.tables["ImagesListTableView"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
//        // Скроллим вверх (до появления новых ячеек)
//        let firstCell = table.cells.element(boundBy: 0)
//        firstCell.swipeUp()
//        
//        // Ждём, когда появится новая ячейка (например, 2-я)
//        let newCell = table.cells.element(boundBy: 1)
//        XCTAssertTrue(newCell.waitForExistence(timeout: 5))

        // Работа с лайком на 2 ячейке
        let cellToLike = table.cells.element(boundBy: 1)
        
        // Прокручиваем до неё, чтобы она была видима
        while !cellToLike.isHittable {
            app.swipeUp()
            }
        
        // Находим кнопку лайка в этой ячейке
        let likeButton = cellToLike.buttons["likeButton"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 3))
        
        // Проверяем начальное состояние (опционально)
        XCTAssertEqual(likeButton.value as? String, "unliked")
        
        // Ставим лайк
        likeButton.tap()
        sleep(1)
        XCTAssertEqual(likeButton.value as? String, "liked")
        
        // Убираем лайк
        likeButton.tap()
        sleep(1)
        XCTAssertEqual(likeButton.value as? String, "unliked")
        
        // Нажимаем на ячейку, чтобы открыть картинку
        cellToLike.tap()
        
        // Ждём загрузки SingleImageViewController
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        let image = scrollView.images.firstMatch
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        
        // Zoom in
        image.pinch(withScale: 3, velocity: 1) 
        // Zoom out
        image.pinch(withScale: 0.5, velocity: -1)
        
        // Возвращаемся назад
        let backButton = app.buttons["BackButton"] // идентификатор для кнопки назад
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()
        
        // Проверяем, что вернулись на ленту
        XCTAssertTrue(table.waitForExistence(timeout: 3))
    }
    
    // MARK: - Сценарий 3: Профиль
    
    func testProfile() throws {
        // Ждём ленту (чтобы быть уверенным, что приложение загрузилось)
        let table = app.tables["ImagesListTableView"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
        // Переход на вкладку профиля (вторая кнопка в TabBar)
        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        profileTab.tap()
        
        // Проверяем наличие элементов профиля (с идентификаторами)
        let nameLabel = app.staticTexts["ProfileNameLabel"]
        let usernameLabel = app.staticTexts["ProfileUsernameLabel"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 3))
        XCTAssertTrue(usernameLabel.exists)
        
        // Нажатие на кнопку логаута
        let logoutButton = app.buttons["logoutButton"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 3))
        logoutButton.tap()
       
        // Подтверждение в алерте
        let alert = app.alerts["Пока, пока!"]
        let yesButton = alert.buttons["Да"]
        XCTAssertTrue(yesButton.waitForExistence(timeout: 3))
        yesButton.tap()
        
        // Проверяем, что открылся экран авторизации (кнопка Authenticate)
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
    }
}

extension XCUIElement {
    func scrollToElement(element: XCUIElement, in app: XCUIApplication, maxAttempts: Int = 10) {
        var attempts = 0
        while !element.isHittable && attempts < maxAttempts {
            app.swipeUp()
            attempts += 1
        }
    }
}
