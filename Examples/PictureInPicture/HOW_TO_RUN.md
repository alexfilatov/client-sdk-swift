# How to Run the Picture in Picture Examples

Since this is a Swift Package (not an Xcode app project), you have three options to run the examples:

## Option 1: Create a New iOS App in Xcode (Recommended)

### Step 1: Create New Project
1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Name it "LiveKitPiPDemo"
5. Choose SwiftUI for interface

### Step 2: Add LiveKit Package
1. In Xcode, go to File → Add Package Dependencies
2. Enter this repo URL: `https://github.com/livekit/client-sdk-swift`
3. Click "Add Package"

### Step 3: Copy Example Code

**For SwiftUI Example:**
```swift
// Replace ContentView.swift with:
import SwiftUI
import LiveKit

@main
struct LiveKitPiPDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PiPSwiftUIView()
        }
    }
}

// Then copy PiPSwiftUIView.swift content from Examples/PictureInPicture/
```

**For UIKit Example:**
```swift
// In AppDelegate.swift or SceneDelegate.swift:
import UIKit
import LiveKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let pipVC = PiPViewController()
        window.rootViewController = pipVC
        self.window = window
        window.makeKeyAndVisible()

        // Connect to LiveKit
        Task {
            try? await pipVC.connect(
                url: "wss://your-server.com",
                token: "your-token"
            )
        }
    }
}

// Then copy PiPViewController.swift content from Examples/PictureInPicture/
```

### Step 4: Enable Background Modes
1. Select your app target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Background Modes"
5. Check "Audio, AirPlay, and Picture in Picture"

### Step 5: Update Connection Details
Replace the placeholder URL and token in the code:
```swift
try? await vc.connect(
    url: "wss://your-livekit-server.com",  // Your LiveKit server
    token: "your-jwt-token"                 // Your LiveKit token
)
```

### Step 6: Run
1. Select an iOS device or simulator (iOS 15.0+)
2. Press Cmd+R to build and run

---

## Option 2: Use the Demo App File

Copy `DemoApp/PiPDemoApp.swift` into a new iOS app project:

1. Create new iOS App in Xcode (SwiftUI template)
2. Add LiveKit package dependency
3. Copy ALL files from `Examples/PictureInPicture/` to your project:
   - `PiPViewController.swift`
   - `PiPSwiftUIView.swift`
   - `DemoApp/PiPDemoApp.swift`
4. Replace your `@main` App struct with the content from `PiPDemoApp.swift`
5. Enable Background Modes (see Step 4 above)
6. Update connection details
7. Run!

This will give you a picker to switch between SwiftUI and UIKit examples.

---

## Option 3: Integrate Into Existing App

If you already have an iOS app:

1. Add LiveKit package dependency:
   ```
   https://github.com/livekit/client-sdk-swift
   ```

2. Copy either `PiPViewController.swift` or `PiPSwiftUIView.swift` to your project

3. Enable Background Modes in your app target

4. Use in your app:

   **SwiftUI:**
   ```swift
   import SwiftUI

   struct MyView: View {
       var body: some View {
           PiPSwiftUIView()
       }
   }
   ```

   **UIKit:**
   ```swift
   import UIKit

   class MyViewController: UIViewController {
       override func viewDidLoad() {
           super.viewDidLoad()

           let pipVC = PiPViewController()
           addChild(pipVC)
           view.addSubview(pipVC.view)
           pipVC.view.frame = view.bounds
           pipVC.didMove(toParent: self)
       }
   }
   ```

---

## Quick Test Without LiveKit Server

To test the UI without connecting to a real server:

1. Comment out the `connect()` call
2. The examples will still show:
   - PiP button (disabled until video track is available)
   - Status messages
   - UI layout

3. To see PiP in action, you'll need:
   - A running LiveKit server (or use LiveKit Cloud)
   - A valid JWT token
   - Another participant in the room sending video

---

## Troubleshooting

### "PiP not supported"
- Check you're running on iOS 15.0+ device/simulator
- Some older simulators may not support PiP

### "PiP button disabled"
- Ensure you have a video track attached
- Check VideoView render mode is `.sampleBuffer`
- Verify background modes are enabled

### "Connection failed"
- Check your server URL is correct
- Verify your JWT token is valid
- Ensure your app has network permissions

### "No video showing"
- Verify another participant is in the room
- Check that participant is publishing video
- Look for track subscription in console logs

---

## Example Server Setup

For a quick test, you can use LiveKit Cloud:

1. Sign up at https://cloud.livekit.io
2. Create a project
3. Get your LiveKit URL (e.g., `wss://your-project.livekit.cloud`)
4. Generate a token from the dashboard or using the CLI
5. Update the connection code with these values

---

## Testing PiP

Once connected with video:

1. Tap "Start PiP" button
2. Press home button or switch apps
3. Video continues in floating PiP window
4. Tap PiP window to return to app
5. Tap "Stop PiP" to exit PiP mode

---

## Need Help?

- Check the main [PiP Documentation](../../Docs/picture-in-picture.md)
- See [LiveKit Swift SDK Docs](https://docs.livekit.io/client-sdk-swift/)
- Report issues on [GitHub](https://github.com/livekit/client-sdk-swift/issues)
