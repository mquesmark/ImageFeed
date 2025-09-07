import UIKit

final class AlertService {
    static let shared = AlertService()
    private init() {}
    
    func showAlert(
        withTitle title: String,
        andMessage message: String?,
        withActions actions: [UIAlertAction] = [UIAlertAction(title: "ОК", style: .default)],
        withAccessibilityIdentifier accessibilityIdentifier: String? = nil,
        on viewController: UIViewController
    ) {
        DispatchQueue.main.async{
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            
            actions.forEach({alert.addAction($0)})
            alert.view.accessibilityIdentifier = accessibilityIdentifier
            viewController.present(alert, animated: true)
        }
        
        
    }
}
