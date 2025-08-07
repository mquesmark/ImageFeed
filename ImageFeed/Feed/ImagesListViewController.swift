import UIKit

final class ImagesListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Private Properties
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
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
    }
    
    // MARK: - Private Methods
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let imageName = String(indexPath.row)
        guard let image = UIImage(named: imageName) else { return }
        cell.cellImage.image = image
        cell.cellDate.text = dateFormatter.string(from: Date())
        if indexPath.row % 2 == 0 {
            cell.cellLike.setImage(UIImage(named: "Active Like"), for: .normal)
        } else {
            cell.cellLike.setImage(UIImage(named: "Inactive Like"), for: .normal)
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
        let imageName = photosName[indexPath.row]
        guard let image = UIImage(named: imageName) else {return 0}
        let realTableViewWidth = tableView.bounds.width - 32
        let imageAspectRatio = image.size.height / image.size.width
        let imageViewHeight = realTableViewWidth * imageAspectRatio
        return imageViewHeight + 8
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}
