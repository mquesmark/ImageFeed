import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: - Public Properties
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            imageView.image = image
            imageView.frame.size = image.size
                rescaleAndCenter(image: image)
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        guard let image else { return }
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenter(image: image)
        
        let swipeBackGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeBack))
        swipeBackGesture.direction = .down
        view.addGestureRecognizer(swipeBackGesture)
    }
    
    // MARK: - Actions
    
    @IBAction private func didTapBackButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }
        
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

// MARK: - Private Methods

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
