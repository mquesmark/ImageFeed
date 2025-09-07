import UIKit
@MainActor
final class CatGameViewController: UIViewController {
    private let baseTransform = CGAffineTransform(scaleX: 1, y: 1)
    private var timer: Timer?
    private var lastFiredHour: Int?
    
    private let errorMessageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypWhiteIOS
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Не получается войти в приложение"
        label.textAlignment = .center
        return label
    }()
    
    private let errorSubtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypWhiteIOS
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = """
Кажется, у приложения закончились
лимиты на подключение к серверу
"""
        
        return label
    }()
    
    private let preTimerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypWhiteIOS
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Попробуй снова через"
        return label
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypWhiteIOS
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    private let catButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(resource: .cat), for: .normal)
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        b.adjustsImageWhenHighlighted = false
        return b
    }()
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Попробовать снова", for: .normal)
        button.setTitleColor(.ypBlackIOS, for: .normal)
        button.backgroundColor = .ypWhiteIOS
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlackIOS
        
        catButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(errorMessageLabel)
        view.addSubview(errorSubtitleLabel)
        view.addSubview(preTimerLabel)
        view.addSubview(timerLabel)
        view.addSubview(catButton)
        view.addSubview(retryButton)
        
        updateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            // Ensure we hop to the MainActor for UI updates under Swift 6 strict concurrency
            Task { @MainActor in
                self?.updateTimer()
            }
        }
        
        NSLayoutConstraint.activate([
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            retryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            retryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            retryButton.heightAnchor.constraint(equalToConstant: 48),
            
            catButton.centerXAnchor.constraint(equalTo: retryButton.centerXAnchor),
            catButton.bottomAnchor.constraint(equalTo: retryButton.topAnchor, constant: 0),
            catButton.widthAnchor.constraint(equalToConstant: 180),
            catButton.heightAnchor.constraint(equalToConstant: 180),
            
            errorMessageLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            errorMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorMessageLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            errorMessageLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            errorSubtitleLabel.topAnchor.constraint(equalTo: errorMessageLabel.bottomAnchor, constant: 32),
            errorSubtitleLabel.centerXAnchor.constraint(equalTo: errorMessageLabel.centerXAnchor),
            errorSubtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            errorSubtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            preTimerLabel.topAnchor.constraint(equalTo: errorSubtitleLabel.bottomAnchor, constant: 16),
            preTimerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            preTimerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            preTimerLabel.centerXAnchor.constraint(equalTo: errorSubtitleLabel.centerXAnchor),
            
            timerLabel.topAnchor.constraint(equalTo: preTimerLabel.bottomAnchor, constant: 16),
            timerLabel.centerXAnchor.constraint(equalTo: preTimerLabel.centerXAnchor),
            timerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            timerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
        catButton.addAction(UIAction { [weak self] _ in
            self?.catJump()
        }, for: .touchUpInside)
        
        retryButton.addAction(UIAction { [weak self] _ in
            self?.catJump()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.dismiss(animated: true)
            }
        }, for: .touchUpInside)
    }
    
    private func setSubtitle(_ text: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 4 // увеличенный межстрочный интервал
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.ypWhiteIOS,
            .paragraphStyle: paragraph
        ]
        errorSubtitleLabel.attributedText = NSAttributedString(string: text, attributes: attrs)
    }
    
    private func catJump() {
        catButton.isUserInteractionEnabled = false
        retryButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.catButton.transform = self.baseTransform.translatedBy(x: 0, y: -200)
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                self.catButton.transform = self.baseTransform
            }) { [weak self] _ in
                self?.catButton.isUserInteractionEnabled = true
                self?.retryButton.isUserInteractionEnabled = true
            }
        }
    }
    
    private func secsUntilNextHour() -> Int {
        let now = Date()
        let calendar = Calendar.current
        if let interval = calendar.dateInterval(of: .hour, for: now) {
            // `end` — это начало следующего часа
            return max(0, Int(interval.end.timeIntervalSince(now).rounded()))
        }
        // Fallback: найдём ближайшее время с минутой и секундой = 0
        let next = calendar.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? now.addingTimeInterval(3600)
        return max(0, Int(next.timeIntervalSince(now).rounded()))
    }
    private func updateTimer() {
        let totalSeconds = secsUntilNextHour()
        let minutes = totalSeconds / Int(60)
        let seconds = totalSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        if totalSeconds > 1 {
            lastFiredHour = nil
        } else if lastFiredHour != hour {
            handleHourHit()
            lastFiredHour = hour
        }
    }
    
    private func handleHourHit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        catJump()
        
        preTimerLabel.text = "Можно пробовать снова 🎉"
        preTimerLabel.font = .boldSystemFont(ofSize: 20)
        
        preTimerLabel.layer.removeAllAnimations()
        preTimerLabel.textColor = .systemGreen
        preTimerLabel.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UIView.transition(with: self.preTimerLabel,
                              duration: 2.25,
                              options: [.transitionCrossDissolve, .curveEaseOut, .beginFromCurrentState],
                              animations: {
                self.preTimerLabel.textColor = .ypWhiteIOS
            })
        }
        
        timer?.invalidate()
        timer = nil
        timerLabel.isHidden = true
    }
    
    deinit {
        timer?.invalidate()
    }
}
