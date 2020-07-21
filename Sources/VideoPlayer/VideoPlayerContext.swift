
import SwiftUI
import AVFoundation

public struct VideoPlayerContext {
    public let player: AVPlayer

    @Binding
    public var isFullScreen: Bool
}
