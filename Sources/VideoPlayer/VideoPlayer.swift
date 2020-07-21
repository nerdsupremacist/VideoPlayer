
import SwiftUI
import AVKit

public struct VideoPlayer<Content : View> : View {
    let player: AVPlayer
    let content: () -> Content

    public init(player: AVPlayer, @ViewBuilder content: @escaping () -> Content) {
        self.player = player
        self.content = content
    }

    public var body: some View {
        InternalVideoPlayer(player: player, content: content)
    }
}

private struct InternalVideoPlayer<Content : View> : UIViewControllerRepresentable {
    let player: AVPlayer
    let content: () -> Content

    init(player: AVPlayer, @ViewBuilder content: @escaping () -> Content) {
        self.player = player
        self.content = content
    }

    class UIViewControllerType : UIViewController {
        var player: AVPlayer!
        var content: Content! {
            didSet {
                if isShowingOverlay {
                    updateShowingOverlay(animated: false)
                }
            }
        }

        private var playerViewController: AVPlayerViewController!
        private var isShowingOverlay = false
        private var previousContentViewController: UIViewController?
        private var timer: Timer?

        deinit {
            timer?.invalidate()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            // Create child view controller
            playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.videoGravity = .resizeAspectFill

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

        func updateShowingOverlay(animated: Bool = false) {
            if let previousContentViewController = previousContentViewController {
                previousContentViewController.removeFromParent()
                previousContentViewController.view.removeFromSuperview()
            }

            if isShowingOverlay {
                let contentViewController = UIHostingController(rootView: content)
                contentViewController.view.backgroundColor = .clear
                contentViewController.view.translatesAutoresizingMaskIntoConstraints = false

                playerViewController.addChild(contentViewController)
                playerViewController.view.addSubview(contentViewController.view)

                let contraints = [
                    playerViewController.view.leadingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor),
                    playerViewController.view.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
                    playerViewController.view.trailingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor),
                    playerViewController.view.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
                ]

                NSLayoutConstraint.activate(contraints)
                contentViewController.didMove(toParent: playerViewController)

                previousContentViewController = contentViewController
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
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let controller = UIViewControllerType()
        controller.player = player
        return controller
    }


    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.content = content()
    }
}
