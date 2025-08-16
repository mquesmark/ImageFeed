import UIKit

final class ImagesListViewController: UIViewController {
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePhotosUpdate), name: ImagesListService.didChangeNotification, object: ImagesListService.shared)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLikeUpdate), name: ImagesListService.didChangeLikeNotification, object: ImagesListService.shared)
        ImagesListService.shared.fetchPhotosNextPage()
    }
    
    // MARK: - Private Methods
    
    @objc private func handleLikeUpdate(_ notification: Notification) {
        guard let photoId = notification.userInfo?["photoId"] as? String,
        let index = photos.firstIndex(where: {$0.id == photoId})
        else { return }
        
        photos = service.photos
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    @objc private func handlePhotosUpdate() {
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
        tableView.showsVerticalScrollIndicator = false

    }
    
    private func configCell(for cell: ImagesListCell, with photo: Photo) {
        cell.cellDate.text = dateFormatter.string(from: photo.createdAt ?? Date())
        cell.cellLike.setImage(UIImage(resource: photo.isLiked ? .activeLike : .inactiveLike), for: .normal)
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
                let indexPath = self.tableView.indexPath(for: cell)
            else {
                return
            }
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            cell.cellImage.contentMode = .scaleAspectFill
            cell.cellImage.backgroundColor = nil
            cell.backgroundColor = nil
        }
    }
    
    private func showSingleImageVC(withIndex indexPath: IndexPath) {
        let singleImageVC = SingleImageViewController()
        singleImageVC.image = UIImage(named: photosName[indexPath.row])
        singleImageVC.modalPresentationStyle = .fullScreen
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
            return 44
        }
        
        let realTableViewWidth = tableView.bounds.width - 32
        let imageAspectRatio = image.size.height / image.size.width
        let imageViewHeight = realTableViewWidth * imageAspectRatio
        return imageViewHeight + 8
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

        let photo = photos[indexPath.row]
        configCell(for: imageListCell, with: photo)
        imageListCell.onLikeTap = { [weak self] in
            guard let self = self else { return }
            let photo = self.photos[indexPath.row]
            ImagesListService.shared.changeLike(
                photoId: photo.id,
                isLiked: photo.isLiked
            ) { result in
                if case let .failure(error) = result {
                    print("Like error:", error)
                }
            }
        }
        return imageListCell
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let amountBeforeEnd = 5
        let triggerIndex = max(0, photos.count - amountBeforeEnd)

        if indexPath.row >= triggerIndex {
            print("Loading next page...")
            ImagesListService.shared.fetchPhotosNextPage()
        }
    }
}
