// Copyright 2024 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import MediaPipeTasksVision
import AVFoundation

/**
 * Class to perform pose detection using MediaPipe PoseLandmarker API
 */
@objc(PoseDetectionService)
class PoseDetectionService: NSObject {
    
    weak var delegate: PoseDetectionServiceDelegate?
    private var poseLandmarker: PoseLandmarker?
    private var runningMode = RunningMode.liveStream
    private var frameStartTimes: [Int: Double] = [:] // Track start times by timestamp
    
    // MARK: - Public
    init(delegate: PoseDetectionServiceDelegate?) {
        super.init()
        self.delegate = delegate
        sendLog("🔧 PoseDetectionService: Initializing...", level: "info")
        setupPoseLandmarker()
    }
    
    // MARK: - Private
    private func sendLog(_ message: String, level: String) {
        print(message) // Still print to console
        delegate?.poseDetectionService(self, didLogMessage: message, level: level)
    }
    
    func detectAsync(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation, timeStamps: Int) {
        guard let poseLandmarker = poseLandmarker else {
            sendLog("❌ PoseDetectionService: PoseLandmarker is nil, cannot process frame", level: "error")
            return
        }
        
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            sendLog("❌ PoseDetectionService: Failed to create MPImage from sample buffer", level: "error")
            return
        }
        
        // Record start time for this frame
        frameStartTimes[timeStamps] = CACurrentMediaTime()
        
        do {
            try poseLandmarker.detectAsync(image: image, timestampInMilliseconds: timeStamps)
            sendLog("📸 PoseDetectionService: Frame sent for detection at timestamp \(timeStamps)", level: "debug")
        } catch {
            sendLog("❌ PoseDetectionService: Error performing pose detection: \(error)", level: "error")
            sendLog("❌ PoseDetectionService: Error details: \(error.localizedDescription)", level: "error")
            frameStartTimes.removeValue(forKey: timeStamps)
        }
    }
    
    // MARK: - Private
    private func setupPoseLandmarker() {
        sendLog("🔧 PoseDetectionService: Setting up pose landmarker...", level: "info")
        guard let modelPath = getModelPath() else {
            sendLog("❌ PoseDetectionService: Failed to load model file.", level: "error")
            return
        }
        sendLog("✅ PoseDetectionService: Model found at path: \(modelPath)", level: "info")
        
        let options = PoseLandmarkerOptions()
        options.runningMode = runningMode
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.baseOptions.modelAssetPath = modelPath
        
        // Set delegate only for live stream mode
        if runningMode == .liveStream {
            options.poseLandmarkerLiveStreamDelegate = self
        }
        
        do {
            poseLandmarker = try PoseLandmarker(options: options)
            sendLog("✅ PoseDetectionService: PoseLandmarker initialized successfully!", level: "info")
            
            // Test if pose landmarker is working
            sendLog("🔧 PoseDetectionService: PoseLandmarker instance created: \(poseLandmarker != nil)", level: "debug")
        } catch {
            sendLog("❌ PoseDetectionService: Failed to create PoseLandmarker: \(error)", level: "error")
            sendLog("❌ PoseDetectionService: Error details: \(error.localizedDescription)", level: "error")
        }
    }
    
    private func getModelPath() -> String? {
        sendLog("🔍 PoseDetectionService: Looking for model file...", level: "info")
        
        // Simple approach: just check bundle resources
        let possibleModelNames = [
            "pose_landmarker_full",
            "pose_landmarker_heavy", 
            "pose_landmarker_lite"
        ]
        
        for modelName in possibleModelNames {
            if let modelPath = Bundle.main.path(forResource: modelName, ofType: "task") {
                sendLog("✅ PoseDetectionService: Model found: \(modelName).task", level: "info")
                
                // Verify file exists and get size
                if FileManager.default.fileExists(atPath: modelPath) {
                    let fileSize = try? FileManager.default.attributesOfItem(atPath: modelPath)[.size] as? Int64
                    sendLog("✅ PoseDetectionService: Model file verified, size: \(fileSize ?? 0) bytes", level: "info")
                    return modelPath
                } else {
                    sendLog("❌ PoseDetectionService: Model file path exists but file not found: \(modelPath)", level: "error")
                }
            }
        }
        
        // Debug: List all files in main bundle
        sendLog("🔍 PoseDetectionService: Listing main bundle contents...", level: "debug")
        if let bundlePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let taskFiles = contents.filter { $0.hasSuffix(".task") }
                sendLog("📋 PoseDetectionService: Found .task files in bundle: \(taskFiles)", level: "info")
                
                // If we find any .task file, use the first one
                if !taskFiles.isEmpty {
                    let taskFile = taskFiles[0]
                    let taskPath = (bundlePath as NSString).appendingPathComponent(taskFile)
                    sendLog("🎯 PoseDetectionService: Using first available task file: \(taskFile)", level: "info")
                    return taskPath
                }
            } catch {
                sendLog("❌ PoseDetectionService: Failed to list bundle contents: \(error)", level: "error")
            }
        }
        
        sendLog("❌ PoseDetectionService: Failed to load model file from bundle.", level: "error")
        return nil
    }
}

// MARK: - PoseLandmarkerLiveStreamDelegate
extension PoseDetectionService: PoseLandmarkerLiveStreamDelegate {
    func poseLandmarker(_ poseLandmarker: PoseLandmarker, didFinishDetection result: PoseLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        // Calculate processing time
        let endTime = CACurrentMediaTime()
        let startTime = frameStartTimes.removeValue(forKey: timestampInMilliseconds) ?? endTime
        let processingTime = (endTime - startTime) * 1000 // Convert to milliseconds
        
        if let error = error {
            sendLog("❌ PoseDetectionService: Detection failed with error: \(error)", level: "error")
            delegate?.poseDetectionService(self, didFailWithError: error, processingTime: processingTime)
            return
        }
        
        guard let result = result else {
            sendLog("⚠️ PoseDetectionService: No result received", level: "warning")
            delegate?.poseDetectionService(self, didFailWithError: nil, processingTime: processingTime)
            return
        }
        
        let landmarkCount = result.landmarks.first?.count ?? 0
        sendLog("🎯 PoseDetectionService: Pose detected! Landmarks: \(landmarkCount), Processing time: \(String(format: "%.1f", processingTime))ms, Timestamp: \(timestampInMilliseconds)", level: "info")
        
        delegate?.poseDetectionService(self, didDetectPose: result, processingTime: processingTime)
    }
}

// MARK: - PoseDetectionServiceDelegate
@objc protocol PoseDetectionServiceDelegate: AnyObject {
    func poseDetectionService(_ service: PoseDetectionService, didDetectPose result: PoseLandmarkerResult, processingTime: Double)
    func poseDetectionService(_ service: PoseDetectionService, didFailWithError error: Error?, processingTime: Double)
    func poseDetectionService(_ service: PoseDetectionService, didLogMessage message: String, level: String)
}
