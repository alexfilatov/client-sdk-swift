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

import Foundation

@available(iOS 15.0, *)
@objc
public protocol PictureInPictureDelegate: AnyObject, Sendable {
    /// Picture in Picture will start
    @objc optional
    func pictureInPictureControllerWillStart(_ pictureInPictureController: PictureInPictureController)

    /// Picture in Picture did start
    @objc optional
    func pictureInPictureControllerDidStart(_ pictureInPictureController: PictureInPictureController)

    /// Picture in Picture will stop
    @objc optional
    func pictureInPictureControllerWillStop(_ pictureInPictureController: PictureInPictureController)

    /// Picture in Picture did stop
    @objc optional
    func pictureInPictureControllerDidStop(_ pictureInPictureController: PictureInPictureController)

    /// Picture in Picture failed to start
    @objc optional
    func pictureInPictureController(_ pictureInPictureController: PictureInPictureController, failedToStartWithError error: Error)

    /// Picture in Picture restore user interface
    /// Return true to indicate that the app has successfully restored the user interface
    @objc optional
    func pictureInPictureController(_ pictureInPictureController: PictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
}

#endif
