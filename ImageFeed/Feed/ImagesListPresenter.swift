import Foundation

@MainActor
protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewProtocol? { get set }
    var numberOfPhotos: Int { get }
    func photo(at indexPath: IndexPath) -> Photo
    
    func viewDidLoad()
    func willDisplayRow(at indexPath: IndexPath)
    func didSelectRow(at indexPath: IndexPath)
    func didTapLike(at indexPath: IndexPath)
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    
    weak var view: ImagesListViewProtocol?
    private let service = ImagesListService.shared
    private var photoCount = 0
    private var observer: NSObjectProtocol?
    
    var numberOfPhotos: Int { service.photos.count }
    func photo(at indexPath: IndexPath) -> Photo { service.photos[indexPath.row] }
    
    func viewDidLoad() {
        photoCount = service.photos.count
        
        observer = NotificationCenter.default.addObserver(forName: ImagesListService.didChangeNotification, object: service, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                let newCount = self.service.photos.count
                guard newCount > self.photoCount else { return }
                
                let indexPaths = (self.photoCount..<newCount).map { IndexPath(row: $0, section: 0)}
                self.photoCount = newCount
                self.view?.insertRows(at: indexPaths)
            }
        }
        service.fetchPhotosNextPage()
    }
    
    func willDisplayRow(at indexPath: IndexPath) {
        let triggerIndex = service.photos.count - 1
        if indexPath.row >= triggerIndex {
            service.fetchPhotosNextPage()
        }
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        let photo = service.photos[indexPath.row]
        guard let url = URL(string: photo.largeImageURL) else { return }
        view?.showSingleImage(url: url)
    }
    
    func didTapLike(at indexPath: IndexPath) {
        let photo = service.photos[indexPath.row]
        let photoId = photo.id
        
        service.changeLike(photoId: photoId, isLiked: photo.isLiked){ [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .success:
                    self.view?.reloadRows(at: [indexPath])
                case .failure(let error):
                    self.view?.showError(error.localizedDescription)
                }
            }
        }
    }
        
    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
