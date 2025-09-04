import XCTest

@testable import ImageFeed

@MainActor
final class ImagesListTests: XCTestCase {
    
    let mockPhoto = Photo(
        id: "1",
        size: CGSize(width: 100, height: 100),
        createdAt: nil,
        welcomeDescription: nil,
        thumbImageURL: "https://example.com/thumb.jpg",
        largeImageURL: "https://example.com/large.jpg",
        isLiked: false
    )
    
    let service = ImagesListService.shared
    
    override func tearDown() {
        ImagesListService.shared.photos.removeAll()
        super.tearDown()
    }
    func testDidSelectRowOpensSingleImage() {
        
        // Given
        let presenter = ImagesListPresenter(service: service)
        let viewSpy = ImagesListViewSpy()
        presenter.view = viewSpy
        
        let photo = mockPhoto
        service.photos = [photo]
        
        // When
        presenter.didSelectRow(at: IndexPath(row: 0, section: 0))
        
        // Then
        XCTAssertTrue(viewSpy.didShowSingleImage)
        XCTAssertEqual(viewSpy.lastURL?.absoluteString, photo.largeImageURL)
    }
    func testDidLikeReloadsRowOnSuccess() {
        // Given
        let fakeService = ImagesListServiceFake()
        let presenter = ImagesListPresenter(service: fakeService)
        let viewSpy = ImagesListViewSpy()
        presenter.view = viewSpy
        
        let photo = mockPhoto
        fakeService.photos = [photo]
        
        let expectation = expectation(description: "reloadRows called")
        viewSpy.onReload = {
            expectation.fulfill()
        }
        // When
        presenter.didTapLike(at: IndexPath(row: 0, section: 0))
        
        // Then
        wait(for: [expectation], timeout: 0.3)
        XCTAssertTrue(viewSpy.didReloadRows)
        XCTAssertEqual(viewSpy.reloadedIndexPaths, [IndexPath(row: 0, section: 0)])
    }
    
    func testLikeFailShowsError() {
        // Given
        let fakeService = ImagesListServiceFake()
        let presenter = ImagesListPresenter(service: fakeService)
        let viewSpy = ImagesListViewSpy()
        presenter.view = viewSpy
        let photo = mockPhoto
        fakeService.photos = [photo]
        fakeService.shouldSucceed = false
        let expectation = expectation(description: "showError called")
        viewSpy.onError = {
            expectation.fulfill()
        }
        
        // When
        presenter.didTapLike(at: IndexPath(row: 0, section: 0))
        
        // Then
        wait(for: [expectation], timeout: 0.3)
        XCTAssertTrue(viewSpy.didShowError)
        XCTAssertFalse(viewSpy.didReloadRows)
    }
    
    func testOnLastRowFuncWillDisplayRowCallsFetchPhotos() {
        // Given
        let fakeService = ImagesListServiceFake()
        let presenter = ImagesListPresenter(service: fakeService)
        
        let photo1 = mockPhoto
        let photo2 = mockPhoto
        fakeService.photos = [photo1, photo2]
        
        // When
        presenter.willDisplayRow(at: IndexPath(row: fakeService.photos.count - 1, section: 0))
        
        // Then
        XCTAssertEqual(fakeService.fetchNextCalls, 1)
        
    }
    

    // MARK: - Helpers
}
    @MainActor
    final class ImagesListViewSpy: ImagesListViewProtocol {
        
        var didShowSingleImage = false
        var lastURL: URL?
        
        var didReloadRows = false
        var reloadedIndexPaths: [IndexPath] = []
        var onReload: (() -> Void)?
        
        var didShowError = false
        var onError: (() -> Void)?
        
        func reloadRows(at indexPaths: [IndexPath]) {
            didReloadRows = true
            reloadedIndexPaths = indexPaths
            onReload?()
        }
        
        func showSingleImage(url: URL) {
            didShowSingleImage = true
            lastURL = url
        }
        
        func showError(_ message: String) {
            didShowError = true
            onError?()
        }
        func insertRows(at indexPaths: [IndexPath]) {}
        
    }
    
    final class ImagesListServiceFake: ImagesListServiceProtocol {
        var shouldSucceed = true
        
        var photos: [Photo] = []
        
        var fetchNextCalls = 0
        
        func changeLike(photoId: String, isLiked: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
            if shouldSucceed {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "test", code: 1)))
            }
        }
        func fetchPhotosNextPage() {
            fetchNextCalls += 1
        }
    }

