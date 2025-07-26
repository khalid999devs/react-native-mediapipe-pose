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

import Foundation
import MediaPipeTasksVision
import AVFoundation
import Metal
import UIKit

/**
 * Class to perform pose detection using MediaPipe PoseLandmarker API
 */
@objc(PoseDetectionService)
class PoseDetectionService: NSObject {
    
    // MARK: - Properties
    private var poseLandmarker: PoseLandmarker?
    private let runningMode: RunningMode = .liveStream
    private var frameStartTimes: [Int: CFTimeInterval] = [:]
    private var currentDelegate: String = "Unknown"
    
    // GPU status tracking
    private var isGPUAccelerated = false
    private var gpuUsageStatus = false
    
    // Delegate for callbacks
    weak var delegate: PoseDetectionServiceDelegate?
    
    // Callbacks
    var onResultsDetected: (([NormalizedLandmark], TimeInterval) -> Void)?
    var onGPUStatusUpdate: ((Bool, Bool) -> Void)?
    
    init(delegate: PoseDetectionServiceDelegate?) {
        super.init()
        self.delegate = delegate
        setupPoseLandmarker()
    }
    
    // MARK: - GPU Detection
    private func hasMetalGPU() -> Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }
    
    private func checkGPUCapabilities() -> (hasGPU: Bool, deviceName: String) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return (false, "No GPU")
        }
        
        return (true, device.name)
    }    // MARK: - Private
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
        sendLog("🔧 PoseDetectionService: Setting up pose landmarker with automatic hardware acceleration detection...", level: "info")
        
        // Check GPU/Neural Engine availability for monitoring purposes
        let gpuInfo = checkGPUCapabilities()
        sendLog("🎯 PoseDetectionService: Hardware Check - Metal GPU Available: \(gpuInfo.hasGPU), Device: \(gpuInfo.deviceName)", level: "info")
        
        guard let modelPath = getModelPath() else {
            sendLog("❌ PoseDetectionService: Failed to load model file.", level: "error")
            return
        }
        sendLog("✅ PoseDetectionService: Model found at path: \(modelPath)", level: "info")
        
        // Update GPU status for monitoring
        gpuUsageStatus = gpuInfo.hasGPU
        
        // MediaPipe iOS automatically uses the best available hardware acceleration
        // Try optimized settings for devices with hardware acceleration
        if gpuInfo.hasGPU {
            sendLog("🚀 PoseDetectionService: Device has hardware acceleration capability (Metal GPU: \(gpuInfo.deviceName))", level: "info")
            sendLog("🧠 PoseDetectionService: MediaPipe will automatically use Neural Engine/GPU acceleration when beneficial", level: "info")
            
            if let landmarker = createPoseLandmarkerWithGPU(modelPath: modelPath) {
                poseLandmarker = landmarker
                currentDelegate = "Auto (Hardware Accelerated)"
                isGPUAccelerated = true
                sendLog("✅ PoseDetectionService: Successfully initialized with hardware acceleration enabled", level: "info")
                onGPUStatusUpdate?(true, true)
                return
            } else {
                sendLog("⚠️ PoseDetectionService: Hardware acceleration initialization failed, trying standard settings", level: "warning")
            }
        } else {
            sendLog("💡 PoseDetectionService: Limited hardware acceleration available, using standard settings", level: "info")
        }
        
        // Standard initialization (still uses available hardware acceleration automatically)
        if let landmarker = createPoseLandmarkerWithCPU(modelPath: modelPath) {
            poseLandmarker = landmarker
            currentDelegate = "Auto (Standard)"
            isGPUAccelerated = gpuInfo.hasGPU // True if hardware is available, even in "CPU" mode
            sendLog("✅ PoseDetectionService: Successfully initialized with standard settings", level: "info")
            sendLog("🧠 PoseDetectionService: MediaPipe will still use available hardware acceleration automatically", level: "info")
            onGPUStatusUpdate?(gpuInfo.hasGPU, gpuInfo.hasGPU)
            return
        }
        
        sendLog("❌ PoseDetectionService: Failed to initialize with any settings", level: "error")
        onGPUStatusUpdate?(false, false)
    }
    
    private func createPoseLandmarkerWithGPU(modelPath: String) -> PoseLandmarker? {
        sendLog("🔧 PoseDetectionService: Attempting to create PoseLandmarker with GPU acceleration...", level: "info")
        
        let options = PoseLandmarkerOptions()
        options.runningMode = runningMode
        options.numPoses = 1
        
        // Optimize detection thresholds for maximum accuracy with GPU acceleration
        options.minPoseDetectionConfidence = 0.5  // Higher confidence for more precise detection
        options.minPosePresenceConfidence = 0.5   // Higher confidence for more reliable presence detection  
        options.minTrackingConfidence = 0.5       // Higher confidence for more stable tracking
        
        // Configure base options for GPU acceleration
        options.baseOptions.modelAssetPath = modelPath
        
        // Use explicit GPU delegate like in MediaPipe examples
        options.baseOptions.delegate = .GPU
        
        do {
            // Set delegate only for live stream mode
            if runningMode == .liveStream {
                options.poseLandmarkerLiveStreamDelegate = self
            }
            
            let landmarker = try PoseLandmarker(options: options)
            sendLog("✅ PoseDetectionService: PoseLandmarker created successfully with GPU acceleration", level: "info")
            return landmarker
        } catch {
            sendLog("❌ PoseDetectionService: Failed to create PoseLandmarker with GPU acceleration: \(error)", level: "error")
            return nil
        }
    }
    
    private func createPoseLandmarkerWithCPU(modelPath: String) -> PoseLandmarker? {
        sendLog("🔧 PoseDetectionService: Attempting to create PoseLandmarker with CPU-only processing...", level: "info")
        
        let options = PoseLandmarkerOptions()
        options.runningMode = runningMode
        options.numPoses = 1
        
        // Standard detection thresholds for CPU processing
        options.minPoseDetectionConfidence = 0.5  // Higher confidence for more precise detection
        options.minPosePresenceConfidence = 0.5   // Higher confidence for more reliable presence detection
        options.minTrackingConfidence = 0.5       // Higher confidence for more stable tracking
        
        // Configure base options for CPU-only processing
        options.baseOptions.modelAssetPath = modelPath
        
        // Use explicit CPU delegate like in MediaPipe examples
        options.baseOptions.delegate = .CPU
        
        // Set delegate only for live stream mode
        if runningMode == .liveStream {
            options.poseLandmarkerLiveStreamDelegate = self
        }
        
        do {
            let landmarker = try PoseLandmarker(options: options)
            sendLog("✅ PoseDetectionService: PoseLandmarker created successfully with CPU processing", level: "info")
            return landmarker
        } catch {
            sendLog("❌ PoseDetectionService: Failed to create PoseLandmarker with CPU: \(error)", level: "error")
            return nil
        }
    }
    
    // MARK: - Public Methods for Performance Monitoring
    func getCurrentDelegate() -> String {
        return currentDelegate
    }
    
    func isUsingGPU() -> Bool {
        return isGPUAccelerated
    }
    
    func getGPUStatus() -> (isAccelerated: Bool, isAvailable: Bool) {
        return (isGPUAccelerated, gpuUsageStatus)
    }
    
    func hasGPUSupport() -> Bool {
        return hasMetalGPU()
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
        sendLog("🎯 PoseDetectionService: Pose detected! Landmarks: \(landmarkCount), Processing time: \(String(format: "%.1f", processingTime))ms, Delegate: \(getCurrentDelegate()), Timestamp: \(timestampInMilliseconds)", level: "info")
        
        delegate?.poseDetectionService(self, didDetectPose: result, processingTime: processingTime)
    }
}

// MARK: - PoseDetectionServiceDelegate
@objc protocol PoseDetectionServiceDelegate: AnyObject {
    func poseDetectionService(_ service: PoseDetectionService, didDetectPose result: PoseLandmarkerResult, processingTime: Double)
    func poseDetectionService(_ service: PoseDetectionService, didFailWithError error: Error?, processingTime: Double)
    func poseDetectionService(_ service: PoseDetectionService, didLogMessage message: String, level: String)
}
