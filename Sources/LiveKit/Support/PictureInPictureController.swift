/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if os(iOS) || os(tvOS) || os(visionOS)

import AVFoundation
import AVKit

/// A controller that manages Picture in Picture playback for LiveKit video.
@available(iOS 15.0, *)
@MainActor
@objc
public class PictureInPictureController: NSObject, Loggable {
    // MARK: - Public Properties

    /// Delegate to receive Picture in Picture events
    public let delegates = MulticastDelegate<PictureInPictureDelegate>(label: "PictureInPictureDelegate")

    /// Whether Picture in Picture is currently active
    @objc
    public var isPictureInPictureActive: Bool {
        pipController?.isPictureInPictureActive ?? false
    }

    /// Whether Picture in Picture is currently suspended
    @objc
    public var isPictureInPictureSuspended: Bool {
        pipController?.isPictureInPictureSuspended ?? false
    }

    /// Whether Picture in Picture is possible with the current configuration
    @objc
    public var isPictureInPicturePossible: Bool {
        pipController?.isPictureInPicturePossible ?? false
    }

    // MARK: - Private Properties

    private var pipController: AVPictureInPictureController?
    private weak var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?

    // MARK: - Static

    /// Whether Picture in Picture is supported on this device
    @objc
    public static var isPictureInPictureSupported: Bool {
        AVPictureInPictureController.isPictureInPictureSupported()
    }

    // MARK: - Initialization

    /// Initialize a Picture in Picture controller with a sample buffer display layer
    /// - Parameter sampleBufferDisplayLayer: The AVSampleBufferDisplayLayer to use for Picture in Picture
    @objc
    public init?(sampleBufferDisplayLayer: AVSampleBufferDisplayLayer) {
        guard Self.isPictureInPictureSupported else {
            log("Picture in Picture is not supported on this device", .warning)
            return nil
        }

        self.sampleBufferDisplayLayer = sampleBufferDisplayLayer

        super.init()

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleBufferDisplayLayer,
            playbackDelegate: self
        )

        let pipController = AVPictureInPictureController(contentSource: contentSource)
        self.pipController = pipController
        pipController.delegate = self
        if #available(iOS 14.2, *) {
            pipController.canStartPictureInPictureAutomaticallyFromInline = false
        }

        log("PictureInPictureController initialized")
    }

    deinit {
        log(nil, .trace)
    }

    // MARK: - Public Methods

    /// Start Picture in Picture
    @objc
    public func startPictureInPicture() {
        guard let pipController else {
            log("Cannot start Picture in Picture: controller is nil", .warning)
            return
        }

        guard pipController.isPictureInPicturePossible else {
            log("Cannot start Picture in Picture: not possible", .warning)
            return
        }

        pipController.startPictureInPicture()
        log("Starting Picture in Picture")
    }

    /// Stop Picture in Picture
    @objc
    public func stopPictureInPicture() {
        guard let pipController else {
            log("Cannot stop Picture in Picture: controller is nil", .warning)
            return
        }

        pipController.stopPictureInPicture()
        log("Stopping Picture in Picture")
    }

    /// Invalidate the Picture in Picture controller
    /// Call this when you're done with the controller
    @objc
    public func invalidate() {
        pipController?.delegate = nil
        pipController = nil
        sampleBufferDisplayLayer = nil
        log("Picture in Picture controller invalidated")
    }
}

// MARK: - AVPictureInPictureControllerDelegate

@available(iOS 15.0, *)
extension PictureInPictureController: AVPictureInPictureControllerDelegate {
    nonisolated public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            log("Picture in Picture will start")
            delegates.notify { $0.pictureInPictureControllerWillStart?(self) }
        }
    }

    nonisolated public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            log("Picture in Picture did start")
            delegates.notify { $0.pictureInPictureControllerDidStart?(self) }
        }
    }

    nonisolated public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            log("Picture in Picture will stop")
            delegates.notify { $0.pictureInPictureControllerWillStop?(self) }
        }
    }

    nonisolated public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            log("Picture in Picture did stop")
            delegates.notify { $0.pictureInPictureControllerDidStop?(self) }
        }
    }

    nonisolated public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                            failedToStartPictureInPictureWithError error: Error)
    {
        Task { @MainActor in
            log("Picture in Picture failed to start with error: \(error)", .error)
            delegates.notify { $0.pictureInPictureController?(self, failedToStartWithError: error) }
        }
    }

    nonisolated public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
    {
        Task { @MainActor in
            log("Picture in Picture restore user interface")
            delegates.notify { delegate in
                delegate.pictureInPictureController?(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
            }
        }
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

@available(iOS 15.0, *)
extension PictureInPictureController: AVPictureInPictureSampleBufferPlaybackDelegate {
    nonisolated public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                            setPlaying playing: Bool)
    {
        Task { @MainActor in
            log("Picture in Picture set playing: \(playing)")
            // For live video streaming, we don't need to pause/resume playback
            // The video will continue streaming regardless of PiP state
        }
    }

    nonisolated public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        // For live streaming, return an indefinite time range
        return CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    nonisolated public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        // For live video, always return false as we're always "playing"
        return false
    }

    nonisolated public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                            didTransitionToRenderSize newRenderSize: CMVideoDimensions)
    {
        Task { @MainActor in
            log("Picture in Picture did transition to render size: \(newRenderSize.width)x\(newRenderSize.height)")
        }
    }

    nonisolated public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                            skipByInterval skipInterval: CMTime,
                                            completion completionHandler: @escaping () -> Void)
    {
        Task { @MainActor in
            log("Picture in Picture skip by interval: \(skipInterval.seconds)")
            // For live streaming, we typically don't support seeking
            completionHandler()
        }
    }
}

#endif
