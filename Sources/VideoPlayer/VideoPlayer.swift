
import SwiftUI
import AVKit

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

extension VideoPlayer where Content == EmptyView {

    public init(player: AVPlayer) {
        self.init(player: player) { EmptyView() }
    }

}

private struct InternalVideoPlayer<Content : View> : UIViewControllerRepresentable {
    let player: AVPlayer
    let content: (VideoPlayerContext) -> Content

    func makeUIViewController(context: Context) -> VideoPlayerWrapperVideController<Content> {
        let controller = UIViewControllerType()
        controller.player = player
        return controller
    }


    func updateUIViewController(_ uiViewController: VideoPlayerWrapperVideController<Content>, context: Context) {
        uiViewController.content = content
    }
}
