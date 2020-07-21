
import SwiftUI
import AVKit

public struct VideoPlayerContext {
    public let player: AVPlayer

    @Binding
    public var isFullScreen: Bool
}

public struct VideoPlayer<Content : View> : View {
    public typealias Context = VideoPlayerContext

    let player: AVPlayer
    let content: (Context) -> Content

    public init(player: AVPlayer,
                @ViewBuilder content: @escaping (Context) -> Content) {

        self.player = player
        self.content = content
    }

    public var body: some View {
        InternalVideoPlayer(player: player, content: content)
    }
}

extension VideoPlayer {

    public init(player: AVPlayer,
                @ViewBuilder content: @escaping () -> Content) {

        self.player = player
        self.content = { _ in content() }
    }

}

private struct InternalVideoPlayer<Content : View> : UIViewControllerRepresentable {
    let player: AVPlayer
    let content: (VideoPlayerContext) -> Content

    class UIViewControllerType : UIViewController, AVPlayerViewControllerDelegate {
        var player: AVPlayer!
        var content: Content! {
            didSet {
                if isShowingOverlay {
                    updateShowingOverlay(animated: false)
                }
            }
        }

        private var playerViewController: AVPlayerViewController!
        private var fullScreenViewController: UIViewController?

        private var isShowingOverlay = false
        private var previousContentViewController: UIViewController?
        private var timer: Timer?

        private var isFullScreen = false
        private lazy var fullScreenBinding = Binding(get: { [unowned self] in self.isFullScreen }, set: { [unowned self] in self.toggle(isFullScreen: $0) })
        lazy var playerContext = VideoPlayerContext(player: player, isFullScreen: fullScreenBinding)

        deinit {
            timer?.invalidate()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            // Create child view controller
            playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.videoGravity = .resizeAspectFill
            playerViewController.delegate = self

            // Layout child properly
            addChild(playerViewController)
            view.addSubview(playerViewController.view)

            let contraints = [
                playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]

            NSLayoutConstraint.activate(contraints)
            playerViewController.didMove(toParent: self)

            // Setup custom controls
            if Content.self != EmptyView.self {
                playerViewController.showsPlaybackControls = false
                let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
                playerViewController.view.addGestureRecognizer(gesture)
            }
        }

        func toggle(isFullScreen: Bool) {
            guard isFullScreen != self.isFullScreen else { return }
            self.isFullScreen = isFullScreen
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
                        previousContentViewController.removeFromParent()
                        previousContentViewController.view.removeFromSuperview()
                    }
                } else {
                    previousContentViewController.removeFromParent()
                    previousContentViewController.view.removeFromSuperview()
                }
            }

            let viewController = fullScreenViewController ?? playerViewController!

            if isShowingOverlay {
                let contentViewController = UIHostingController(rootView: content.edgesIgnoringSafeArea(isFullScreen ? .all : []))
                if animated {
                    contentViewController.view.alpha = 0
                }
                contentViewController.view.backgroundColor = .clear
                contentViewController.view.translatesAutoresizingMaskIntoConstraints = false

                viewController.addChild(contentViewController)
                viewController.view.addSubview(contentViewController.view)

                let contraints = [
                    viewController.view.leadingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor),
                    viewController.view.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
                    viewController.view.trailingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor),
                    viewController.view.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
                ]

                NSLayoutConstraint.activate(contraints)
                contentViewController.didMove(toParent: viewController)

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

            updateShowingOverlay(animated: true)
        }

        func playerViewController(_ playerViewController: AVPlayerViewController,
                                  willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {


            let previouslyShowingOverlay = isShowingOverlay
            isShowingOverlay = false
            updateShowingOverlay()

            fullScreenViewController = coordinator.viewController(forKey: .to)
            guard let fullScreenViewController = fullScreenViewController else { return }

            // Setup custom controls
            if Content.self != EmptyView.self {
                playerViewController.showsPlaybackControls = false
                let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
                fullScreenViewController.view.addGestureRecognizer(gesture)
            }

            isShowingOverlay = previouslyShowingOverlay
            updateShowingOverlay()
        }

        func playerViewController(_ playerViewController: AVPlayerViewController,
                                  willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            fullScreenViewController = nil
        }
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let controller = UIViewControllerType()
        controller.player = player
        return controller
    }


    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.content = content(uiViewController.playerContext)
    }
}

extension AVPlayerViewController {

    fileprivate func toggle(isFullScreen: Bool, completionHandler: (() -> Void)? = nil) {
        let selector = Selector(
            isFullScreen ? "_transitionToFullScreenAnimated:interactive:completionHandler:" : "_transitionFromFullScreenAnimated:interactive:completionHandler:"
        )

        assert(responds(to: selector), "iOS just broke your App doofus!")
        let imp = method(for: selector)!
        let function = unsafeBitCast(imp, to: (@convention(c) (Any?, Bool, Bool, Any?) -> Void).self)
        function(self, true, true, completionHandler)
    }

}
