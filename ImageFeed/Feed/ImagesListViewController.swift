import UIKit

final class ImagesListViewController: UIViewController {
    private enum Constants {
        static let minimumCellHeight: CGFloat = 44
        static let cellInsets: CGFloat = 32
        static let cellSpacing: CGFloat = 8
    }
    let service = ImagesListService.shared
    
    var photos: [Photo] = []
    
    // MARK: - Private Properties
    private var tableView = UITableView()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let photosName: [String] = Array(0..<20).map { "\($0)" }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableViewAnimated), name: ImagesListService.didChangeNotification, object: ImagesListService.shared)
        
        ImagesListService.shared.fetchPhotosNextPage()
    }
    
    // MARK: - Private Methods
    
    @objc private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = service.photos
        let newPhotosCount = newPhotos.count
        
        guard newPhotosCount > oldCount else { return }
        
        photos = newPhotos
        
        if oldCount > 0, newPhotosCount > oldCount {
            print("oldCount:", oldCount, "newCount:", newPhotosCount)
            print("IDs[last old]:", photos[oldCount - 1].id)
            print("IDs[first new]:", photos[oldCount].id)
        }
        
        let newIndexPaths = (oldCount..<newPhotosCount).map { IndexPath(row: $0, section: 0)}
        
        tableView.performBatchUpdates{
            tableView.insertRows(at: newIndexPaths, with: .automatic)
        }
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.backgroundColor = .ypBlackIOS
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        
    }
    
    private func configCell(for cell: ImagesListCell, with photo: Photo) {
        if let createdAt: Date = photo.createdAt {
            cell.cellDate.text = dateFormatter.string(from: createdAt)
        } else {
            cell.cellDate.text = nil
        }
        cell.setIsLiked(photo.isLiked)
        cell.cellImage.contentMode = .center
        cell.cellImage.backgroundColor = .ypBackgroundIOS
        cell.cellImage.kf.indicatorType = .activity
        cell.cellImage.kf.setImage(with:
                                    URL(string: photo.thumbImageURL),
                                   placeholder: UIImage(resource: .stub)
        ) {
            [weak self, weak cell] result in
            guard
                case .success = result,
                let self,
                let cell,
                let _ = self.tableView.indexPath(for: cell)
            else {
                return
            }
            cell.cellImage.contentMode = .scaleAspectFill
            cell.cellImage.backgroundColor = nil
            cell.backgroundColor = nil
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
    
    private func showSingleImageVC(withIndex indexPath: IndexPath) {
        let singleImageVC = SingleImageViewController()
        singleImageVC.modalPresentationStyle = .fullScreen
        singleImageVC.imageUrl = photos[indexPath.row].largeImageURL
        present(singleImageVC, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showSingleImageVC(withIndex: indexPath)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let image = photos[indexPath.row]
        guard image.size.width > 0 else {
            return Constants.minimumCellHeight
        }
        let realTableViewWidth = tableView.bounds.width - Constants.cellInsets
        let imageAspectRatio = image.size.height / image.size.width
        let imageViewHeight = realTableViewWidth * imageAspectRatio
        return imageViewHeight + Constants.cellSpacing
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        imageListCell.delegate = self
        
        let photo = photos[indexPath.row]
        configCell(for: imageListCell, with: photo)
        return imageListCell
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let triggerIndex = photos.count - 1
        
        if indexPath.row >= triggerIndex {
            print("Loading next page...")
            ImagesListService.shared.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        let photoId = photo.id
        UIBlockingProgressHUD.show()
        
        ImagesListService.shared.changeLike(photoId: photoId, isLiked: photo.isLiked){ [weak self, weak cell] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    guard let self, let cell else { return }
                    defer {
                        UIBlockingProgressHUD.dismiss()
                    }
                    self.photos = ImagesListService.shared.photos
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        cell.setIsLiked(self.photos[index].isLiked)
                    }
                }
            case .failure(let error):
                print("Failed to change like: \(error)")
                DispatchQueue.main.async {
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
}
