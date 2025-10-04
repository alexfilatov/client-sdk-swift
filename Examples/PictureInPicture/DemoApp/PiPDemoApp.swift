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

#if os(iOS)

import SwiftUI

/// Demo app entry point for Picture in Picture examples
@main
struct PiPDemoApp: App {

    @State private var selectedExample: Example = .swiftUI

    var body: some Scene {
        WindowGroup {
            NavigationView {
                VStack(spacing: 20) {
                    Text("LiveKit PiP Examples")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose an example to run")
                        .foregroundColor(.secondary)

                    Picker("Example", selection: $selectedExample) {
                        Text("SwiftUI").tag(Example.swiftUI)
                        Text("UIKit").tag(Example.uikit)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    Group {
                        switch selectedExample {
                        case .swiftUI:
                            PiPSwiftUIView()
                        case .uikit:
                            PiPUIKitWrapper()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
            }
        }
    }

    enum Example {
        case swiftUI
        case uikit
    }
}

/// Wrapper to show UIKit example in SwiftUI
struct PiPUIKitWrapper: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> PiPViewController {
        let vc = PiPViewController()

        // Auto-connect for demo (replace with your LiveKit server)
        Task {
            // Uncomment and add your server details:
            // try? await vc.connect(
            //     url: "wss://your-livekit-server.com",
            //     token: "your-token"
            // )
        }

        return vc
    }

    func updateUIViewController(_ uiViewController: PiPViewController, context: Context) {
        // No updates needed
    }
}

#endif
