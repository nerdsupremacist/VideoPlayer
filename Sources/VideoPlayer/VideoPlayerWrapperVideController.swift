

import SwiftUI
import AVKit

class VideoPlayerWrapperVideController<Content : View> : UIViewController, AVPlayerViewControllerDelegate {
    // Content from SwiftUI
    var player: AVPlayer!
    var content: ((VideoPlayerContext) -> Content)! {
        didSet {
            if isShowingOverlay {
                updateShowingOverlay(animated: false)
            }
        }
    }

    // Children
    private var playerViewController: AVPlayerViewController!
    private var fullScreenViewController: UIViewController?

    // Overlay
    private var isShowingOverlay = false
    private var previousContentViewController: UIViewController?
    private var timer: Timer?

    // Full Screen
    private var _isFullScreen = false
    var isFullScreen: Binding<Bool>!

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpBindings()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpBindings()
    }

    deinit {
        timer?.invalidate()
    }

    func setUpBindings()  {
        isFullScreen = Binding(get: { [unowned self] in self._isFullScreen }, set: { [unowned self] in self.toggle(isFullScreen: $0) })
    }


    func setupTapGestureIfNeeded(viewController: UIViewController) {
        if Content.self != EmptyView.self {
            if let playerViewController = viewController as? AVPlayerViewController {
                playerViewController.showsPlaybackControls = false
            }

            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
            viewController.view.addGestureRecognizer(gesture)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create child view controller
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.videoGravity = .resizeAspectFill
        playerViewController.delegate = self

        // Layout child properly
        insert(child: playerViewController)
        setupTapGestureIfNeeded(viewController: playerViewController)
    }

    func toggle(isFullScreen: Bool) {
        guard isFullScreen != _isFullScreen else { return }
        _isFullScreen = isFullScreen
        if isFullScreen {
            playerViewController.toggle(isFullScreen: isFullScreen)
        } else {
            fullScreenViewController?.dismiss(animated: true)
        }
    }

    func updateShowingOverlay(animated: Bool = false) {
        if let previousContentViewController = previousContentViewController {
            if animated {
                UIView.animate(withDuration: 0.3, animations: { previousContentViewController.view.alpha = 0 }) { _ in
                    previousContentViewController.remove()
                }
            } else {
                previousContentViewController.remove()
            }
        }

        let viewController = fullScreenViewController ?? playerViewController!

        if isShowingOverlay {
            let contentViewController = UIHostingController(rootView: content(VideoPlayerContext(player: player, isFullScreen: isFullScreen)))
            if animated {
                contentViewController.view.alpha = 0
            }
            contentViewController.view.backgroundColor = .clear
            contentViewController.view.translatesAutoresizingMaskIntoConstraints = false

            UIView.performWithoutAnimation {
                viewController.insert(child: contentViewController)
            }
            previousContentViewController = contentViewController

            if animated {
                UIView.animate(withDuration: 0.3) {
                    contentViewController.view.alpha = 1
                }
            }
        } else {
            previousContentViewController = nil
        }
    }

    @objc func tapped(_ sender: UITapGestureRecognizer) {
        timer?.invalidate()
        isShowingOverlay.toggle()

        if isShowingOverlay {
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [unowned self] _ in
                self.isShowingOverlay = false
                self.updateShowingOverlay(animated: true)
            }
        }

        updateShowingOverlay()
    }

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        let previouslyShowingOverlay = isShowingOverlay
        isShowingOverlay = false
        updateShowingOverlay()

        fullScreenViewController = coordinator.viewController(forKey: .to)
        guard let fullScreenViewController = fullScreenViewController else { return }

        setupTapGestureIfNeeded(viewController: fullScreenViewController)
        isShowingOverlay = previouslyShowingOverlay
        updateShowingOverlay(animated: true)
    }

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        fullScreenViewController = nil
    }
}
