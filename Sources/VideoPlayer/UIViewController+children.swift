
import UIKit

extension UIViewController {

    func insert(child viewController: UIViewController) {
        // Layout child properly
        addChild(viewController)
        view.addSubview(viewController.view)

        let contraints = [
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        NSLayoutConstraint.activate(contraints)
        viewController.didMove(toParent: self)
    }

    func remove() {
        removeFromParent()
        view.removeFromSuperview()
    }

}
