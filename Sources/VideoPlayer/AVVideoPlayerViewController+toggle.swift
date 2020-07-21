
import AVKit

extension AVPlayerViewController {

    func toggle(isFullScreen: Bool, completionHandler: (() -> Void)? = nil) {
        let selector = Selector(
            isFullScreen ? "_transitionToFullScreenAnimated:interactive:completionHandler:" : "_transitionFromFullScreenAnimated:interactive:completionHandler:"
        )

        assert(responds(to: selector), "iOS just broke your App doofus!")
        let imp = method(for: selector)!
        let function = unsafeBitCast(imp, to: (@convention(c) (Any?, Bool, Bool, Any?) -> Void).self)
        function(self, true, false, completionHandler)
    }

}
