
import XCTest
@testable import ImageFeed

// MARK: - Tests
@MainActor
final class WebViewTests: XCTestCase {
    
    // 1. Связь контроллера и презентера
    func testViewControllerCallsViewDidLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WebViewViewController") as! WebViewViewController
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        // when
        _ = viewController.view // принудительно загружаем view, вызывается viewDidLoad
        
        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    // 2. Презентер вызывает loadRequest у контроллера
    func testPresenterCallsLoadRequest() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let viewController = WebViewViewControllerSpy()
        presenter.view = viewController
        viewController.presenter = presenter
        
        // when
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(viewController.loadRequestCalled)
    }
    
    // 3. shouldHideProgress: меньше 1 → false
    func testProgressVisibleWhenLessThenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6
        
        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // then
        XCTAssertFalse(shouldHideProgress)
    }
    
    // 4. shouldHideProgress: равно 1 → true
    func testProgressHiddenWhenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0
        
        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // then
        XCTAssertTrue(shouldHideProgress)
    }
    
    // 5. AuthHelper генерирует правильный URL
    func testAuthHelperAuthURL() {
        // given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        // when
        guard let url = authHelper.authURL() else {
            XCTFail("Auth URL is nil")
            return
        }
        let urlString = url.absoluteString
        
        // then
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    // 6. AuthHelper извлекает code из URL
    func testCodeFromURL() {
        // given
        let authHelper = AuthHelper()
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        guard let url = urlComponents.url else {
            XCTFail("Test URL is nil")
            return
        }
        
        // when
        let code = authHelper.code(from: url)
        
        // then
        XCTAssertEqual(code, "test code")
    }
}
