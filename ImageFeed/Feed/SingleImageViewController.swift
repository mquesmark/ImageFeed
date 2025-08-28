import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    // MARK: - Public Properties
    var imageUrl: String?
    
    // MARK: - Private Properties
    
    private var imageView = UIImageView()
    private var scrollView = UIScrollView()
    private var backButton = UIButton(type: .custom)
    private var shareButton = UIButton(type: .custom)
    
    private var imageViewEdgeConstraints: [NSLayoutConstraint] = []
    private var imageViewSizeConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupActions()
        setupConstraints()
        setImage()
    }
    
    // MARK: - Private Methods
    
    private func showError() {
        let actions = [
            UIAlertAction(title: "Не надо", style: .cancel) { [weak self] _ in
                self?.dismiss(animated: true)
            },
            UIAlertAction(title: "Повторить", style: .default){[weak self] _ in
                self?.setImage()
            }
        ]
        AlertService.shared.showAlert(withTitle: "Что-то пошло не так", andMessage: "Попробовать ещё раз?", withActions: actions, on: self)    }
    
    private func setImage() {
        guard let imageUrl,
              let url = URL(string: imageUrl) else {
            print("No image URL")
            return
        }
        
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: url, placeholder: UIImage(resource: .stub)) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            
            switch result {
            case .success(let value):
                self.deactivateImageViewTempConstraints()
                self.imageView.frame.size = value.image.size
                self.imageView.contentMode = .scaleAspectFit
                self.rescaleAndCenter(image: value.image)
                
            case .failure(let error):
                self.showError()
                print("Error in downloading image: \(error)")
                return
            }
        }
    }
    private func setupViews() {
        view.backgroundColor = .ypBlackIOS
        backButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        view.addSubview(backButton)
        view.addSubview(shareButton)
        scrollView.addSubview(imageView)
        imageView.frame.size = view.frame.size
        imageView.contentMode = .center
    }
    
    private func setupActions() {
        
        backButton.setImage(UIImage(resource: .backward), for: .normal)
        let backAction = UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }
        backButton.addAction(backAction, for: .touchUpInside)
        
        shareButton.setImage(UIImage(resource: .sharing), for: .normal)
        let shareAction = UIAction { [weak self] _ in
            self?.didTapShareButton()
        }
        shareButton.addAction(shareAction, for: .touchUpInside)
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeBack))
        swipeDownGesture.direction = .down
        view.addGestureRecognizer(swipeDownGesture)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 48),
            backButton.heightAnchor.constraint(equalToConstant: 48),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17),
            
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        imageViewEdgeConstraints = [
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ]
        
        imageViewSizeConstraints = [
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ]
        
        NSLayoutConstraint.activate(imageViewEdgeConstraints + imageViewSizeConstraints)
    }
    
    private func deactivateImageViewTempConstraints() {
        NSLayoutConstraint.deactivate(imageViewEdgeConstraints + imageViewSizeConstraints)
        imageViewEdgeConstraints.removeAll()
        imageViewSizeConstraints.removeAll()
        imageView.translatesAutoresizingMaskIntoConstraints = true
    }
    private func didTapShareButton() {
        guard let image = imageView.image else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    @objc private func handleSwipeBack() {
        dismiss(animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        updateScrollViewInsets()
    }
}

// MARK: - Zoom Private Methods

extension SingleImageViewController {
    private func rescaleAndCenter(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
        updateScrollViewInsets()
    }
    
    private func updateScrollViewInsets() {
        let visibleRectSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        
        let hInset = max(0, (visibleRectSize.width - contentSize.width) / 2)
        let vInset = max(0, (visibleRectSize.height - contentSize.height) / 2)
        
        UIView.animate(withDuration: 0.25) {
            self.scrollView.contentInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
        }
    }
}
