# Picture in Picture (PiP) Implementation for LiveKit Swift SDK

This document explains how to use the Picture in Picture functionality that has been implemented in the LiveKit Swift SDK.

## Overview

Picture in Picture (PiP) allows video to continue playing in a floating, resizable window while the user interacts with other apps. This implementation solves the renderer invalidation issue mentioned in GitHub issue #458 by using a dedicated, persistent `AVSampleBufferDisplayLayer` for PiP that survives renderer recreation.

## Requirements

- iOS 15.0+ / iPadOS 15.0+ / tvOS 15.0+ / visionOS 1.0+
- LiveKit Swift SDK with PiP support
- Your app must have the "Audio, AirPlay, and Picture in Picture" background mode enabled in Xcode capabilities

## Key Features

- ✅ Dedicated PiP layer that persists across renderer changes
- ✅ Automatic frame mirroring to PiP layer
- ✅ Support for rotation and mirroring transformations
- ✅ Delegate callbacks for PiP lifecycle events
- ✅ Thread-safe implementation

## Architecture

The implementation consists of three main components:

1. **PictureInPictureController** - Wrapper around `AVPictureInPictureController` that manages PiP state and delegates
2. **PictureInPictureDelegate** - Protocol for receiving PiP lifecycle events
3. **VideoView PiP Extensions** - Methods to prepare, start, stop, and cleanup PiP

## Basic Usage

### 1. Enable Background Modes

In Xcode, add the "Audio, AirPlay, and Picture in Picture" background mode to your app target:
1. Select your app target
2. Go to the "Signing & Capabilities" tab
3. Add "Background Modes" capability
4. Enable "Audio, AirPlay, and Picture in Picture"

### 2. Set Render Mode to Sample Buffer

PiP requires the `sampleBuffer` render mode:

```swift
let videoView = VideoView()
videoView.renderMode = .sampleBuffer
videoView.track = participant.videoTrack
```

### 3. Prepare Picture in Picture

Before starting PiP, you need to prepare it:

```swift
// This creates the dedicated PiP layer and controller
if videoView.preparePictureInPicture() {
    print("PiP prepared successfully")
} else {
    print("Failed to prepare PiP")
}
```

### 4. Start and Stop Picture in Picture

```swift
// Start PiP
videoView.startPictureInPicture()

// Stop PiP
videoView.stopPictureInPicture()
```

### 5. Check PiP State

```swift
// Check if PiP is supported on the device
if VideoView.isPictureInPictureSupported {
    print("PiP is supported")
}

// Check if PiP is currently active
if videoView.isPictureInPictureActive {
    print("PiP is active")
}

// Check if PiP is possible (ready to start)
if videoView.isPictureInPicturePossible {
    print("PiP can be started")
}
```

### 6. Cleanup (Optional)

When you're done with PiP, you can clean up resources:

```swift
videoView.cleanupPictureInPicture()
```

## Complete Example

```swift
import UIKit
import LiveKit

class VideoCallViewController: UIViewController {
    var room: Room?
    var videoView: VideoView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create video view with sampleBuffer mode for PiP support
        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer
        view.addSubview(videoView)
        self.videoView = videoView

        // Setup constraints...

        // Connect to room and attach video track
        connectToRoom()
    }

    func connectToRoom() async {
        let room = Room()
        self.room = room

        // Connect to room...
        try? await room.connect(url: "wss://your-livekit-server", token: "your-token")

        // When a participant joins, attach their video track
        room.delegates.add(delegate: self)
    }

    @IBAction func togglePictureInPicture(_ sender: UIButton) {
        guard let videoView = videoView else { return }

        if videoView.isPictureInPictureActive {
            // Stop PiP
            videoView.stopPictureInPicture()
        } else {
            // Prepare and start PiP
            if videoView.preparePictureInPicture() {
                videoView.startPictureInPicture()
            }
        }
    }
}

extension VideoCallViewController: RoomDelegate {
    func room(_ room: Room, participant: RemoteParticipant, didSubscribe publication: TrackPublication, track: Track) {
        if let videoTrack = track as? VideoTrack {
            DispatchQueue.main.async {
                self.videoView?.track = videoTrack
            }
        }
    }
}
```

## Using PiP Delegate

To receive PiP lifecycle events, implement the `PictureInPictureDelegate` protocol:

```swift
class MyViewController: UIViewController, PictureInPictureDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer

        // Prepare PiP
        videoView.preparePictureInPicture()

        // Add yourself as a delegate
        videoView.pictureInPictureController?.delegates.add(delegate: self)
    }

    // MARK: - PictureInPictureDelegate

    func pictureInPictureControllerWillStart(_ pictureInPictureController: PictureInPictureController) {
        print("PiP will start")
    }

    func pictureInPictureControllerDidStart(_ pictureInPictureController: PictureInPictureController) {
        print("PiP did start")
    }

    func pictureInPictureControllerWillStop(_ pictureInPictureController: PictureInPictureController) {
        print("PiP will stop")
    }

    func pictureInPictureControllerDidStop(_ pictureInPictureController: PictureInPictureController) {
        print("PiP did stop")
    }

    func pictureInPictureController(_ pictureInPictureController: PictureInPictureController,
                                   failedToStartWithError error: Error) {
        print("PiP failed to start: \(error)")
    }

    func pictureInPictureController(_ pictureInPictureController: PictureInPictureController,
                                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Restore your UI when user taps the PiP window to return to full screen
        // Call completionHandler(true) when done
        print("Restore UI for PiP stop")

        // Example: Navigate back to the video view controller
        // navigationController?.popToViewController(self, animated: true)

        completionHandler(true)
    }
}
```

## SwiftUI Example

```swift
import SwiftUI
import LiveKit

struct VideoCallView: View {
    @StateObject private var room = Room()
    @State private var isPiPActive = false

    var body: some View {
        VStack {
            // Use VideoView with SwiftUI
            VideoViewRepresentable(track: room.remoteParticipants.first?.videoTrack)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: togglePiP) {
                Text(isPiPActive ? "Stop PiP" : "Start PiP")
            }
        }
        .onAppear {
            connectToRoom()
        }
    }

    private func togglePiP() {
        // Toggle PiP implementation
    }

    private func connectToRoom() {
        // Connect to room...
    }
}

struct VideoViewRepresentable: UIViewRepresentable {
    let track: VideoTrack?

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.renderMode = .sampleBuffer
        return view
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        uiView.track = track
    }
}
```

## Important Notes

1. **Render Mode**: PiP requires `renderMode` to be set to `.sampleBuffer`. Metal rendering mode does not support PiP.

2. **Background Modes**: Ensure you've enabled the "Audio, AirPlay, and Picture in Picture" background mode in your app's capabilities.

3. **Persistence**: The PiP layer persists across renderer recreation, solving the issue where PiP would break when the video track state changed.

4. **Live Streaming**: This implementation is optimized for live video streaming. The playback delegate methods always return that the video is "playing" since there's no pause/resume for live streams.

5. **Thread Safety**: All PiP operations are thread-safe and can be called from any thread.

## Troubleshooting

### PiP doesn't start

- Check that `VideoView.isPictureInPictureSupported` returns `true`
- Ensure `renderMode` is set to `.sampleBuffer`
- Verify that background modes are properly configured
- Make sure you called `preparePictureInPicture()` before `startPictureInPicture()`

### PiP breaks when video pauses/resumes

- This implementation specifically addresses this issue by using a dedicated, persistent layer
- Ensure you're using the latest version with PiP support

### PiP window shows incorrect rotation

- The implementation automatically syncs rotation and mirroring from the main layer
- If you experience issues, file a bug report with reproduction steps

## References

- [Apple's PiP Documentation](https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls)
- [AVPictureInPictureController](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller)
- [LiveKit Swift SDK GitHub Issue #458](https://github.com/livekit/client-sdk-swift/issues/458)
