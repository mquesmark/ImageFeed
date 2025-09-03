import XCTest

@testable import ImageFeed

@MainActor
final class ProfilePresenterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        ProfileService.shared.profile = nil
        ProfileImageService.shared.avatarURL = nil
    }
    override func tearDown() {
        ProfileService.shared.profile = nil
        ProfileImageService.shared.avatarURL = nil
        super.tearDown()
    }
    
    func testViewDidLoadSetsProfileDetailsWhenProfileExists() {
        // Given
        let view = MockProfileView()
        let presenter = ProfilePresenter()
        presenter.view = view
        let profileResult = ProfileService.ProfileResult(
            username: "maximgv3",
            firstName: "Max",
            lastName: "Gvazava",
            bio: "Hello, world!"
        )
        ProfileService.shared.profile = ProfileService.Profile(profileResult: profileResult)
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(view.didShowDetails)
        XCTAssertEqual(view.lastName, "Max Gvazava")
        XCTAssertEqual(view.lastUsername, "@maximgv3")
        XCTAssertEqual(view.lastBio, "Hello, world!")
    }
    
    func testViewDidLoadDoesntChangeDetailsWhenProfileIsNil() {
        // Given
        let view = MockProfileView()
        let presenter = ProfilePresenter()
        presenter.view = view
        ProfileService.shared.profile = nil
        // When
        presenter.viewDidLoad()
        
        //Then
        XCTAssertFalse(view.didShowDetails)
        XCTAssertEqual(view.lastName, "")
        XCTAssertEqual(view.lastUsername, "")
        XCTAssertEqual(view.lastBio, "")
    }
    
    func testViewDidLoadChangesAvatarWhenURLExists() {
        // Given
        let view = MockProfileView()
        let presenter = ProfilePresenter()
        presenter.view = view
        ProfileImageService.shared.avatarURL = "https://example.com/avatar.jpg"
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(view.didShowAvatar)
        XCTAssertEqual(view.lastURL?.absoluteString, "https://example.com/avatar.jpg")
    }

    
    func testViewDidLoadDoesntChangeAvatarWhenURLIsNil() {
        // Given
        let view = MockProfileView()
        let presenter = ProfilePresenter()
        presenter.view = view
        ProfileImageService.shared.avatarURL = nil
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertFalse(view.didShowAvatar)
    }
    
    func testDidTapLogoutAlertShowsLogoutAlert() {
        let view = MockProfileView()
        let presenter = ProfilePresenter()
        presenter.view = view
        
        presenter.didTapLogout()
        
        XCTAssertTrue(view.didShowLogoutAlert)
        
    }
}

@MainActor

final class MockProfileView: ProfileViewControllerProtocol {
    
    var lastName = ""
    var lastUsername = ""
    var lastBio = ""
    var lastURL: URL?
    
    var didShowDetails = false
    var didShowAvatar = false
    var didShowLogoutAlert = false
    func showProfileDetails(
        personName: String,
        username: String,
        profileDescription: String,
    ) {
        didShowDetails = true
        lastName = personName
        lastBio = profileDescription
        lastUsername = username
    }
    
    func showAvatar(url: URL) {
        didShowAvatar = true
        lastURL = url
    }
    
    func showLogoutAlert() {
        didShowLogoutAlert = true
    }
    
}
