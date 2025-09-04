import UIKit

@MainActor
protocol ImagesListViewProtocol: AnyObject {
    func insertRows(at indexPaths: [IndexPath])
    func reloadRows(at indexPaths: [IndexPath])
    func showSingleImage(url: URL)
    func showError(_ message: String)
}

final class ImagesListViewController: UIViewController, ImagesListViewProtocol {

    private enum Constants {
        static let minimumCellHeight: CGFloat = 44
        static let cellInsets: CGFloat = 32
        static let cellSpacing: CGFloat = 8
    }
    var presenter: ImagesListPresenterProtocol?

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
        if presenter == nil {
            presenter = ImagesListPresenter(service: ImagesListService.shared)
        }
        presenter?.view = self
        presenter?.viewDidLoad()
        setupTableView()
    }

    func insertRows(at indexPaths: [IndexPath]) {
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        } completion: { _ in
            self.tableView.reloadData()
        }
    }

    func reloadRows(at indexPaths: [IndexPath]) {
        UIBlockingProgressHUD.dismiss()
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }

    func showError(_ message: String) {
        UIBlockingProgressHUD.dismiss()
        AlertService.shared.showAlert(
            withTitle: "Ошибка",
            andMessage: message,
            on: self
        )
    }

    func showSingleImage(url: URL) {
        let singleImageVC = SingleImageViewController()
        singleImageVC.modalPresentationStyle = .fullScreen
        singleImageVC.imageUrl = url.absoluteString
        present(singleImageVC, animated: true)
    }

    // MARK: - Private Methods

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        tableView.register(
            ImagesListCell.self,
            forCellReuseIdentifier: ImagesListCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: 12,
            right: 0
        )
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
        cell.cellImage.kf.setImage(
            with:
                URL(string: photo.thumbImageURL),
            placeholder: UIImage(resource: .stub)
        ) {
            [weak self, weak cell] result in
            guard
                case .success = result,
                let self,
                let cell,
                self.tableView.indexPath(for: cell) != nil
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
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        presenter?.didSelectRow(at: indexPath)
    }
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        guard let photo = presenter?.photo(at: indexPath) else {
            return Constants.minimumCellHeight
        }
        guard photo.size.width > 0 else {
            return Constants.minimumCellHeight
        }
        let realTableViewWidth = tableView.bounds.width - Constants.cellInsets
        let imageAspectRatio = photo.size.height / photo.size.width
        let imageViewHeight = realTableViewWidth * imageAspectRatio
        return imageViewHeight + Constants.cellSpacing
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return presenter?.numberOfPhotos ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )

        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }

        imageListCell.delegate = self

        guard let photo = presenter?.photo(at: indexPath) else { return UITableViewCell() }
        configCell(for: imageListCell, with: photo)
        return imageListCell
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        presenter?.willDisplayRow(at: indexPath)
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        UIBlockingProgressHUD.show()
        presenter?.didTapLike(at: indexPath)
    }
}
