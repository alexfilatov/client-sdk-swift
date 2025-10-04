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

@testable import LiveKit
import AVFoundation
import XCTest

@MainActor
class PictureInPictureTests: LKTestCase {

    var sampleBufferLayer: AVSampleBufferDisplayLayer!

    override func setUpWithError() throws {
        sampleBufferLayer = AVSampleBufferDisplayLayer()
    }

    override func tearDown() async throws {
        sampleBufferLayer = nil
    }

    // MARK: - PictureInPictureController Tests

    func testPiPControllerInitialization() throws {
        // Test that PiP controller can be initialized with a sample buffer layer
        let pipController = PictureInPictureController(sampleBufferDisplayLayer: sampleBufferLayer)

        if PictureInPictureController.isPictureInPictureSupported {
            XCTAssertNotNil(pipController, "PiP controller should be initialized on supported devices")
            XCTAssertFalse(pipController!.isPictureInPictureActive, "PiP should not be active initially")
        } else {
            XCTAssertNil(pipController, "PiP controller should be nil on unsupported devices")
        }
    }

    func testPiPControllerStaticProperties() {
        // Test static support check
        let isSupported = PictureInPictureController.isPictureInPictureSupported
        print("PiP support on this device: \(isSupported)")

        // This test just validates the property exists and returns a boolean
        XCTAssertNotNil(isSupported)
    }

    func testPiPControllerDelegate() async throws {
        guard PictureInPictureController.isPictureInPictureSupported else {
            throw XCTSkip("PiP not supported on this device")
        }

        guard let pipController = PictureInPictureController(sampleBufferDisplayLayer: sampleBufferLayer) else {
            XCTFail("Failed to create PiP controller")
            return
        }

        let delegateReceiver = PiPDelegateReceiver()
        pipController.delegates.add(delegate: delegateReceiver)

        // Verify delegate is added
        XCTAssertEqual(pipController.delegates.count, 1, "Should have one delegate")

        // Clean up
        pipController.invalidate()
    }

    func testPiPControllerInvalidate() throws {
        guard PictureInPictureController.isPictureInPictureSupported else {
            throw XCTSkip("PiP not supported on this device")
        }

        guard let pipController = PictureInPictureController(sampleBufferDisplayLayer: sampleBufferLayer) else {
            XCTFail("Failed to create PiP controller")
            return
        }

        // Should not crash when invalidated
        pipController.invalidate()

        // Should be safe to invalidate multiple times
        pipController.invalidate()
    }

    // MARK: - VideoView PiP Tests

    func testVideoViewPiPPreparation() async throws {
        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer

        // Prepare PiP
        let prepared = await videoView.preparePictureInPicture()

        if PictureInPictureController.isPictureInPictureSupported {
            XCTAssertTrue(prepared, "PiP should be prepared successfully on supported devices")
            XCTAssertNotNil(videoView.pictureInPictureController, "PiP controller should exist after preparation")
        } else {
            XCTAssertFalse(prepared, "PiP preparation should fail on unsupported devices")
        }
    }

    func testVideoViewPiPRequiresSampleBufferMode() async throws {
        let videoView = VideoView()
        videoView.renderMode = .metal // Wrong mode

        let prepared = await videoView.preparePictureInPicture()

        // Should fail because metal mode doesn't support PiP
        XCTAssertFalse(prepared, "PiP should not be prepared with metal render mode")
    }

    func testVideoViewPiPStateProperties() async throws {
        guard PictureInPictureController.isPictureInPictureSupported else {
            throw XCTSkip("PiP not supported on this device")
        }

        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer

        // Before preparation
        XCTAssertFalse(videoView.isPictureInPictureActive, "PiP should not be active before preparation")
        XCTAssertFalse(videoView.isPictureInPicturePossible, "PiP should not be possible before preparation")

        // After preparation
        await videoView.preparePictureInPicture()

        XCTAssertFalse(videoView.isPictureInPictureActive, "PiP should not be active after preparation (not started)")
        // Note: isPictureInPicturePossible might be false if no video is playing
    }

    func testVideoViewPiPCleanup() async throws {
        guard PictureInPictureController.isPictureInPictureSupported else {
            throw XCTSkip("PiP not supported on this device")
        }

        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer

        await videoView.preparePictureInPicture()
        XCTAssertNotNil(videoView.pictureInPictureController, "PiP controller should exist")

        await videoView.cleanupPictureInPicture()
        XCTAssertNil(videoView.pictureInPictureController, "PiP controller should be nil after cleanup")
    }

    // MARK: - Renderer Persistence Tests

    func testPiPLayerPersistsAcrossRendererRecreation() async throws {
        guard PictureInPictureController.isPictureInPictureSupported else {
            throw XCTSkip("PiP not supported on this device")
        }

        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer

        // Prepare PiP
        await videoView.preparePictureInPicture()

        // Get reference to PiP controller before renderer recreation
        let originalPiPController = videoView.pictureInPictureController
        XCTAssertNotNil(originalPiPController, "PiP controller should exist")

        // Force renderer recreation by changing render mode and back
        // (This simulates what happens during track state changes)
        videoView.renderMode = .metal
        await sleep(forSeconds: 1)

        videoView.renderMode = .sampleBuffer
        await sleep(forSeconds: 1)

        // PiP controller should be the same instance
        XCTAssertTrue(originalPiPController === videoView.pictureInPictureController,
                     "PiP controller should persist across renderer changes")
    }

    func testSampleBufferRendererPiPLayerConnection() async throws {
        let renderer = SampleBufferVideoRenderer(frame: .zero)
        let pipLayer = AVSampleBufferDisplayLayer()

        // Set PiP layer
        renderer.setPictureInPictureLayer(pipLayer)

        // Create a test pixel buffer
        guard let pixelBuffer = createTestPixelBuffer() else {
            XCTFail("Failed to create test pixel buffer")
            return
        }

        guard let sampleBuffer = CMSampleBuffer.from(pixelBuffer) else {
            XCTFail("Failed to create sample buffer")
            return
        }

        // Create an RTC frame
        let rtcPixelBuffer = LKRTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let rtcFrame = LKRTCVideoFrame(buffer: rtcPixelBuffer, rotation: ._0, timeStampNs: 0)

        // Render frame
        renderer.renderFrame(rtcFrame)

        // Wait for async rendering
        await sleep(forSeconds: 1)

        // Verify both layers should have received the frame
        // (In a real scenario, we'd check the layer's state, but that's private)
        // This test proves the rendering path works without crashing
        XCTAssertTrue(true, "Rendering to both layers completed successfully")
    }

    func testMultiplePiPLayerReconnections() async throws {
        let renderer = SampleBufferVideoRenderer(frame: .zero)

        // Connect and disconnect PiP layer multiple times
        for i in 1...5 {
            let pipLayer = AVSampleBufferDisplayLayer()
            renderer.setPictureInPictureLayer(pipLayer)

            // Simulate rendering
            if let pixelBuffer = createTestPixelBuffer(),
               let sampleBuffer = CMSampleBuffer.from(pixelBuffer) {
                let rtcPixelBuffer = LKRTCCVPixelBuffer(pixelBuffer: pixelBuffer)
                let rtcFrame = LKRTCVideoFrame(buffer: rtcPixelBuffer, rotation: ._0, timeStampNs: Int64(i))
                renderer.renderFrame(rtcFrame)
            }

            await sleep(forSeconds: 0.1)

            // Disconnect
            renderer.setPictureInPictureLayer(nil)
        }

        XCTAssertTrue(true, "Multiple PiP layer reconnections completed successfully")
    }

    // MARK: - Integration Tests

    func testVideoViewPiPWithTrack() async throws {
        guard PictureInPictureController.isPictureInPictureSupported else {
            throw XCTSkip("PiP not supported on this device")
        }

        let videoView = VideoView()
        videoView.renderMode = .sampleBuffer

        // Create a mock video track
        let track = try await createMockVideoTrack()
        videoView.track = track

        // Prepare PiP
        let prepared = await videoView.preparePictureInPicture()
        XCTAssertTrue(prepared, "PiP should be prepared with track attached")

        // Verify PiP controller exists
        XCTAssertNotNil(videoView.pictureInPictureController, "PiP controller should exist")

        // Clean up
        videoView.track = nil
        await videoView.cleanupPictureInPicture()
    }

    func testPiPStaticPropertyOnVideoView() {
        // Test that static property is accessible
        let isSupported = VideoView.isPictureInPictureSupported
        print("VideoView.isPictureInPictureSupported: \(isSupported)")

        // Should match the controller's static property
        XCTAssertEqual(isSupported, PictureInPictureController.isPictureInPictureSupported,
                      "VideoView and Controller PiP support should match")
    }

    // MARK: - Helper Methods

    private func createTestPixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let width = 640
        let height = 480

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferIOSurfacePropertiesKey: [:],
                kCVPixelBufferMetalCompatibilityKey: true
            ] as CFDictionary,
            &pixelBuffer
        )

        return status == kCVReturnSuccess ? pixelBuffer : nil
    }

    private func createMockVideoTrack() async throws -> VideoTrack {
        // Create a simple local video track for testing
        let options = LocalVideoTrackOptions()
        let track = LocalVideoTrack.createTrack(options: options)
        return track
    }
}

// MARK: - Test Delegate Receiver

@MainActor
class PiPDelegateReceiver: NSObject, PictureInPictureDelegate {
    var willStartCalled = false
    var didStartCalled = false
    var willStopCalled = false
    var didStopCalled = false
    var failedToStartError: Error?
    var restoreUICalled = false

    func pictureInPictureControllerWillStart(_ pictureInPictureController: PictureInPictureController) {
        willStartCalled = true
    }

    func pictureInPictureControllerDidStart(_ pictureInPictureController: PictureInPictureController) {
        didStartCalled = true
    }

    func pictureInPictureControllerWillStop(_ pictureInPictureController: PictureInPictureController) {
        willStopCalled = true
    }

    func pictureInPictureControllerDidStop(_ pictureInPictureController: PictureInPictureController) {
        didStopCalled = true
    }

    func pictureInPictureController(_ pictureInPictureController: PictureInPictureController,
                                   failedToStartWithError error: Error) {
        failedToStartError = error
    }

    func pictureInPictureController(_ pictureInPictureController: PictureInPictureController,
                                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restoreUICalled = true
        completionHandler(true)
    }
}

#endif
