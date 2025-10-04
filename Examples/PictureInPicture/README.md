# Picture in Picture Example

This directory contains example implementations of Picture in Picture (PiP) functionality using LiveKit Swift SDK.

## Files

- **`PiPViewController.swift`** - UIKit implementation
- **`PiPSwiftUIView.swift`** - SwiftUI implementation

## Requirements

### App Configuration

1. **Enable Background Modes** in your app target:
   - Open your project in Xcode
   - Select your app target
   - Go to "Signing & Capabilities" tab
   - Add "Background Modes" capability
   - Enable "Audio, AirPlay, and Picture in Picture"

2. **Info.plist** - Ensure microphone/camera permissions are set if using local video:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access is required for video calls</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Microphone access is required for video calls</string>
   ```

### Platform Support

- iOS 15.0+
- iPadOS 15.0+
- tvOS 15.0+
- visionOS 1.0+

## UIKit Example Usage

```swift
import UIKit
import LiveKit

class MyViewController: UIViewController {

    let pipVC = PiPViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add PiP view controller
        addChild(pipVC)
        view.addSubview(pipVC.view)
        pipVC.view.frame = view.bounds
        pipVC.didMove(toParent: self)

        // Connect to LiveKit
        Task {
            try? await pipVC.connect(
                url: "wss://your-livekit-server.com",
                token: "your-token"
            )
        }
    }
}
```

## SwiftUI Example Usage

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            PiPSwiftUIView()
        }
    }
}
```

## How It Works

### 1. VideoView Setup

PiP requires the VideoView to use `sampleBuffer` render mode:

```swift
let videoView = VideoView()
videoView.renderMode = .sampleBuffer  // Required for PiP
```

### 2. Prepare PiP

Before starting PiP, prepare the controller:

```swift
if videoView.preparePictureInPicture() {
    print("PiP ready")
}
```

### 3. Start/Stop PiP

```swift
// Start
videoView.startPictureInPicture()

// Stop
videoView.stopPictureInPicture()

// Check status
if videoView.isPictureInPictureActive {
    print("PiP is active")
}
```

### 4. Handle Lifecycle (Optional)

Implement `PictureInPictureDelegate` to receive callbacks:

```swift
extension MyViewController: PictureInPictureDelegate {
    func pictureInPictureControllerDidStart(_ controller: PictureInPictureController) {
        print("PiP started")
    }

    func pictureInPictureControllerDidStop(_ controller: PictureInPictureController) {
        print("PiP stopped")
    }

    func pictureInPictureController(_ controller: PictureInPictureController,
                                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // User tapped PiP window to return to app
        // Restore your UI here
        completionHandler(true)
    }
}
```

### 5. Add Delegate

```swift
videoView.pictureInPictureController?.delegates.add(delegate: self)
```

## Key Features Demonstrated

Both examples show:

- ✅ Checking PiP support (`VideoView.isPictureInPictureSupported`)
- ✅ Setting up VideoView with correct render mode
- ✅ Connecting to LiveKit room
- ✅ Handling video track subscription
- ✅ Starting/stopping PiP
- ✅ PiP status monitoring
- ✅ Error handling
- ✅ UI restoration when returning from PiP
- ✅ Proper cleanup on disconnect

## Testing

1. Build and run the example on an iOS device or simulator
2. Connect to a LiveKit room with video
3. Tap "Start PiP" button
4. Press home button - video continues in floating window
5. Tap floating window to return to app
6. Tap "Stop PiP" to exit PiP mode

## Common Issues

### PiP Button Disabled

- Ensure device supports PiP
- Verify VideoView has a video track attached
- Check render mode is set to `.sampleBuffer`

### PiP Breaks on Track Changes

This SDK version includes a fix that maintains PiP across renderer recreation, so this shouldn't happen. If it does, file an issue.

### PiP Doesn't Start

- Check background modes are enabled
- Verify audio session is configured correctly
- Ensure app is in foreground when starting PiP

## Learn More

- [Full PiP Documentation](../../Docs/picture-in-picture.md)
- [LiveKit Swift SDK Docs](https://docs.livekit.io/client-sdk-swift/)
- [Apple PiP Documentation](https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls)
