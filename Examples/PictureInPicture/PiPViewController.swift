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

import UIKit
import LiveKit

/// Example UIKit view controller demonstrating Picture in Picture functionality
class PiPViewController: UIViewController {

    // MARK: - Properties

    private let room = Room()
    private var videoView: VideoView!
    private var pipButton: UIButton!
    private var statusLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRoom()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black

        // Video view - must use sampleBuffer mode for PiP
        videoView = VideoView()
        videoView.renderMode = .sampleBuffer
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)

        // Status label
        statusLabel = UILabel()
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // PiP button
        pipButton = UIButton(type: .system)
        pipButton.setTitle("Start PiP", for: .normal)
        pipButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        pipButton.backgroundColor = .systemBlue
        pipButton.setTitleColor(.white, for: .normal)
        pipButton.layer.cornerRadius = 8
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        pipButton.addTarget(self, action: #selector(pipButtonTapped), for: .touchUpInside)
        view.addSubview(pipButton)

        // Layout
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: pipButton.topAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            pipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pipButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        updateUI()
    }

    private func setupRoom() {
        room.delegates.add(delegate: self)

        // Check PiP support
        if VideoView.isPictureInPictureSupported {
            statusLabel.text = "PiP Supported ✓"
        } else {
            statusLabel.text = "PiP Not Supported ✗"
            pipButton.isEnabled = false
            pipButton.alpha = 0.5
        }
    }

    // MARK: - Actions

    @objc private func pipButtonTapped() {
        Task { @MainActor in
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

    // MARK: - Connection

    func connect(url: String, token: String) async throws {
        try await room.connect(url: url, token: token)
        updateUI()
    }

    func disconnect() async {
        await room.disconnect()
        videoView.cleanupPictureInPicture()
        updateUI()
    }

    // MARK: - UI Updates

    private func updateUI() {
        Task { @MainActor in
            let isPiPActive = videoView.isPictureInPictureActive
            pipButton.setTitle(isPiPActive ? "Stop PiP" : "Start PiP", for: .normal)
            pipButton.isEnabled = videoView.track != nil && VideoView.isPictureInPictureSupported

            if let track = videoView.track {
                statusLabel.text = isPiPActive ? "PiP Active" : "Video Ready"
            } else {
                statusLabel.text = room.connectionState == .connected ? "Waiting for video..." : "Not connected"
            }
        }
    }
}

// MARK: - RoomDelegate

extension PiPViewController: RoomDelegate {

    func room(_ room: Room, participant: RemoteParticipant, didSubscribe publication: TrackPublication, track: Track) {
        guard let videoTrack = track as? VideoTrack else { return }

        Task { @MainActor in
            videoView.track = videoTrack
            updateUI()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribe publication: TrackPublication, track: Track) {
        Task { @MainActor in
            if videoView.track === track {
                videoView.track = nil
                updateUI()
            }
        }
    }

    func room(_ room: Room, didUpdate connectionState: ConnectionState, from oldValue: ConnectionState) {
        updateUI()
    }
}

// MARK: - PictureInPictureDelegate (Optional)

extension PiPViewController: PictureInPictureDelegate {

    func pictureInPictureControllerWillStart(_ controller: PictureInPictureController) {
        print("PiP will start")
        updateUI()
    }

    func pictureInPictureControllerDidStart(_ controller: PictureInPictureController) {
        print("PiP did start")
        updateUI()
    }

    func pictureInPictureControllerWillStop(_ controller: PictureInPictureController) {
        print("PiP will stop")
        updateUI()
    }

    func pictureInPictureControllerDidStop(_ controller: PictureInPictureController) {
        print("PiP did stop")
        updateUI()
    }

    func pictureInPictureController(_ controller: PictureInPictureController,
                                   failedToStartWithError error: Error) {
        print("PiP failed to start: \(error)")

        Task { @MainActor in
            let alert = UIAlertController(
                title: "PiP Failed",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    func pictureInPictureController(_ controller: PictureInPictureController,
                                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Restore your UI when user taps PiP to return to app
        print("Restoring UI from PiP")

        // If you need to navigate back to this view controller, do it here
        // For example: navigationController?.popToViewController(self, animated: true)

        completionHandler(true)
    }
}

#endif
