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
import LiveKit

/// Example SwiftUI view demonstrating Picture in Picture functionality
struct PiPSwiftUIView: View {

    @StateObject private var viewModel = PiPViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Status
                Text(viewModel.statusText)
                    .foregroundColor(.white)
                    .padding()

                // Video view
                PiPVideoView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Controls
                VStack(spacing: 12) {
                    // PiP button
                    Button(action: viewModel.togglePiP) {
                        HStack {
                            Image(systemName: viewModel.isPiPActive ? "pip.exit" : "pip.enter")
                            Text(viewModel.isPiPActive ? "Stop PiP" : "Start PiP")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canUsePiP)
                    .opacity(viewModel.canUsePiP ? 1.0 : 0.5)

                    // Connect/Disconnect button
                    Button(action: {
                        Task {
                            if viewModel.isConnected {
                                await viewModel.disconnect()
                            } else {
                                await viewModel.connect(
                                    url: "wss://your-livekit-server.com",
                                    token: "your-token"
                                )
                            }
                        }
                    }) {
                        Text(viewModel.isConnected ? "Disconnect" : "Connect")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isConnected ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .alert("PiP Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - VideoView UIViewRepresentable

struct PiPVideoView: UIViewRepresentable {
    @ObservedObject var viewModel: PiPViewModel

    func makeUIView(context: Context) -> VideoView {
        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer
        videoView.backgroundColor = .black

        // Store reference in view model
        DispatchQueue.main.async {
            viewModel.videoView = videoView
        }

        return videoView
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        uiView.track = viewModel.videoTrack
    }
}

// MARK: - ViewModel

@MainActor
class PiPViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var statusText: String = "Not connected"
    @Published var isPiPActive: Bool = false
    @Published var isConnected: Bool = false
    @Published var canUsePiP: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var videoTrack: VideoTrack?

    // MARK: - Properties

    private let room = Room()
    var videoView: VideoView? {
        didSet {
            updatePiPStatus()
            setupPiPDelegate()
        }
    }

    // MARK: - Initialization

    init() {
        room.delegates.add(delegate: self)
        canUsePiP = VideoView.isPictureInPictureSupported

        if !canUsePiP {
            statusText = "PiP not supported on this device"
        }
    }

    // MARK: - Actions

    func togglePiP() {
        guard let videoView = videoView else { return }

        if isPiPActive {
            videoView.stopPictureInPicture()
        } else {
            if videoView.preparePictureInPicture() {
                videoView.startPictureInPicture()
            } else {
                showError(message: "Failed to prepare PiP")
            }
        }
    }

    func connect(url: String, token: String) async {
        do {
            try await room.connect(url: url, token: token)
            isConnected = true
            statusText = "Connected - Waiting for video..."
        } catch {
            showError(message: "Connection failed: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        await room.disconnect()
        videoView?.cleanupPictureInPicture()
        isConnected = false
        videoTrack = nil
        isPiPActive = false
        statusText = "Disconnected"
    }

    // MARK: - Private

    private func setupPiPDelegate() {
        guard let videoView = videoView else { return }

        // Add PiP delegate after preparing
        if videoView.preparePictureInPicture() {
            videoView.pictureInPictureController?.delegates.add(delegate: self)
        }
    }

    private func updatePiPStatus() {
        guard let videoView = videoView else { return }
        isPiPActive = videoView.isPictureInPictureActive
        canUsePiP = videoTrack != nil && VideoView.isPictureInPictureSupported
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - RoomDelegate

extension PiPViewModel: RoomDelegate {

    nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribe publication: TrackPublication, track: Track) {
        guard let videoTrack = track as? VideoTrack else { return }

        Task { @MainActor in
            self.videoTrack = videoTrack
            statusText = "Video connected"
            updatePiPStatus()
        }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnsubscribe publication: TrackPublication, track: Track) {
        Task { @MainActor in
            if self.videoTrack === track {
                self.videoTrack = nil
                statusText = isConnected ? "Video disconnected" : "Disconnected"
                updatePiPStatus()
            }
        }
    }

    nonisolated func room(_ room: Room, didUpdate connectionState: ConnectionState, from oldValue: ConnectionState) {
        Task { @MainActor in
            isConnected = connectionState == .connected
        }
    }
}

// MARK: - PictureInPictureDelegate

extension PiPViewModel: PictureInPictureDelegate {

    nonisolated func pictureInPictureControllerWillStart(_ controller: PictureInPictureController) {
        Task { @MainActor in
            isPiPActive = true
            statusText = "PiP Starting..."
        }
    }

    nonisolated func pictureInPictureControllerDidStart(_ controller: PictureInPictureController) {
        Task { @MainActor in
            isPiPActive = true
            statusText = "PiP Active"
        }
    }

    nonisolated func pictureInPictureControllerWillStop(_ controller: PictureInPictureController) {
        Task { @MainActor in
            statusText = "PiP Stopping..."
        }
    }

    nonisolated func pictureInPictureControllerDidStop(_ controller: PictureInPictureController) {
        Task { @MainActor in
            isPiPActive = false
            statusText = videoTrack != nil ? "Video connected" : "Disconnected"
        }
    }

    nonisolated func pictureInPictureController(_ controller: PictureInPictureController,
                                                failedToStartWithError error: Error) {
        Task { @MainActor in
            showError(message: "PiP failed: \(error.localizedDescription)")
        }
    }

    nonisolated func pictureInPictureController(_ controller: PictureInPictureController,
                                                restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Restore UI when returning from PiP
        Task { @MainActor in
            print("Restoring UI from PiP")
            completionHandler(true)
        }
    }
}

// MARK: - Preview

struct PiPSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        PiPSwiftUIView()
    }
}

#endif
