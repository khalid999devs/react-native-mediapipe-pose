/**
 * Pose detection service using MediaPipe BlazePose
 * Provides GPU-accelerated pose landmark detection with automatic fallback to CPU
 */

import Foundation
import MediaPipeTasksVision
import AVFoundation
import Metal
import UIKit

/**
 * Delegate protocol for pose detection callbacks
 */
protocol PoseDetectionServiceDelegate: AnyObject {
    func poseDetectionService(_ service: PoseDetectionService, didDetectPose result: PoseLandmarkerResult, processingTime: Double)
    func poseDetectionService(_ service: PoseDetectionService, didFailWithError error: Error?, processingTime: Double)
    func poseDetectionService(_ service: PoseDetectionService, didLogMessage message: String, level: String)
}

/**
 * High-performance pose detection service with GPU acceleration
 */
@objc(PoseDetectionService)
class PoseDetectionService: NSObject {
    
    // MARK: - Core Properties
    private var poseLandmarker: PoseLandmarker?
    private let runningMode: RunningMode = .liveStream
    private var frameStartTimes: [Int: CFTimeInterval] = [:]
    private var currentDelegate: String = "Unknown"
    
    // Hardware acceleration tracking
    private var isGPUAccelerated = false
    private var gpuUsageStatus = false
    
    // Delegate for callbacks
    weak var delegate: PoseDetectionServiceDelegate?
    
    // Performance callbacks
    var onResultsDetected: (([NormalizedLandmark], TimeInterval) -> Void)?
    var onGPUStatusUpdate: ((Bool, Bool) -> Void)?
    
    /**
     * Initialize pose detection service with delegate
     */
    init(delegate: PoseDetectionServiceDelegate?) {
        super.init()
        self.delegate = delegate
        setupPoseLandmarker()
    }
    
    // MARK: - GPU Detection
    /**
     * Check if Metal GPU is available
     */
    private func hasMetalGPU() -> Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }
    
    /**
     * Get GPU capabilities and device information
     */
    private func checkGPUCapabilities() -> (hasGPU: Bool, deviceName: String) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return (false, "No GPU")
        }
        return (true, device.name)
    }
    
    // MARK: - Logging
    /**
     * Send log message to delegate (only if detailed logging enabled)
     */
    private func sendLog(_ message: String, level: String) {
        delegate?.poseDetectionService(self, didLogMessage: message, level: level)
    }
    
    /**
     * Asynchronously detect pose landmarks in video frame
     */
    func detectAsync(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation, timeStamps: Int) {
        guard let poseLandmarker = poseLandmarker else {
            sendLog("PoseLandmarker not initialized", level: "error")
            return
        }
        
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            sendLog("Failed to create MPImage from sample buffer", level: "error")
            return
        }
        
        frameStartTimes[timeStamps] = CACurrentMediaTime()
        
        do {
            try poseLandmarker.detectAsync(image: image, timestampInMilliseconds: timeStamps)
        } catch {
            sendLog("Pose detection failed: \(error.localizedDescription)", level: "error")
            frameStartTimes.removeValue(forKey: timeStamps)
        }
    }
    
    // MARK: - Setup
    /**
     * Initialize pose landmarker with automatic hardware acceleration
     */
    private func setupPoseLandmarker() {        
        guard let modelPath = getModelPath() else {
            sendLog("Model file not found", level: "error")
            return
        }
        
        let gpuInfo = checkGPUCapabilities()
        gpuUsageStatus = gpuInfo.hasGPU
        
        // Try GPU acceleration first on capable devices
        if gpuInfo.hasGPU {
            if let landmarker = createPoseLandmarkerWithGPU(modelPath: modelPath) {
                poseLandmarker = landmarker
                currentDelegate = "GPU"
                isGPUAccelerated = true
                onGPUStatusUpdate?(true, true)
                return
            }
        }
        
        // Fallback to CPU with available hardware acceleration
        if let landmarker = createPoseLandmarkerWithCPU(modelPath: modelPath) {
            poseLandmarker = landmarker
            currentDelegate = "CPU"
            isGPUAccelerated = gpuInfo.hasGPU
            onGPUStatusUpdate?(gpuInfo.hasGPU, gpuInfo.hasGPU)
            return
        }
        
        sendLog("Pose detection service initialization failed", level: "error")
        onGPUStatusUpdate?(false, false)
    }
    
    /**
     * Create pose landmarker with GPU acceleration for maximum performance
     */
    private func createPoseLandmarkerWithGPU(modelPath: String) -> PoseLandmarker? {
        let options = PoseLandmarkerOptions()
        options.runningMode = runningMode
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.baseOptions.modelAssetPath = modelPath
        options.baseOptions.delegate = .GPU
        
        if runningMode == .liveStream {
            options.poseLandmarkerLiveStreamDelegate = self
        }
        
        do {
            return try PoseLandmarker(options: options)
        } catch {
            sendLog("GPU acceleration initialization failed: \(error.localizedDescription)", level: "error")
            return nil
        }
    }
    
    /**
     * Create pose landmarker with CPU processing and available hardware acceleration
     */
    private func createPoseLandmarkerWithCPU(modelPath: String) -> PoseLandmarker? {
        let options = PoseLandmarkerOptions()
        options.runningMode = runningMode
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.baseOptions.modelAssetPath = modelPath
        options.baseOptions.delegate = .CPU
        
        if runningMode == .liveStream {
            options.poseLandmarkerLiveStreamDelegate = self
        }
        
        do {
            return try PoseLandmarker(options: options)
        } catch {
            sendLog("CPU initialization failed: \(error.localizedDescription)", level: "error")
            return nil
        }
    }
    
    // MARK: - Public Interface
    /**
     * Get current MediaPipe delegate type
     */
    func getCurrentDelegate() -> String {
        return currentDelegate
    }
    
    /**
     * Check if GPU acceleration is currently active
     */
    func isUsingGPU() -> Bool {
        return isGPUAccelerated
    }
    
    /**
     * Get comprehensive GPU status information
     */
    func getGPUStatus() -> (isAccelerated: Bool, isAvailable: Bool) {
        return (isGPUAccelerated, gpuUsageStatus)
    }
    
    /**
     * Check if device supports GPU acceleration
     */
    func hasGPUSupport() -> Bool {
        return hasMetalGPU()
    }
    
    /**
     * Locate MediaPipe pose detection model file
     */
    private func getModelPath() -> String? {
        let possibleModelNames = [
            "pose_landmarker_full",
            "pose_landmarker_heavy", 
            "pose_landmarker_lite"
        ]
        
        for modelName in possibleModelNames {
            if let modelPath = Bundle.main.path(forResource: modelName, ofType: "task") {
                if FileManager.default.fileExists(atPath: modelPath) {
                    return modelPath
                }
            }
        }
        
        // Fallback: scan bundle for any .task file
        sendLog("🔍 PoseDetectionService: Listing main bundle contents...", level: "debug")
        if let bundlePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let taskFiles = contents.filter { $0.hasSuffix(".task") }
                if let firstTaskFile = taskFiles.first {
                    return (bundlePath as NSString).appendingPathComponent(firstTaskFile)
                }
            } catch {
                sendLog("Failed to scan bundle contents: \(error.localizedDescription)", level: "error")
            }
        }
        
        return nil
    }
}

// MARK: - MediaPipe Delegate
extension PoseDetectionService: PoseLandmarkerLiveStreamDelegate {
    func poseLandmarker(_ poseLandmarker: PoseLandmarker, didFinishDetection result: PoseLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        let endTime = CACurrentMediaTime()
        let startTime = frameStartTimes.removeValue(forKey: timestampInMilliseconds) ?? endTime
        let processingTime = (endTime - startTime) * 1000
        
        if let error = error {
            delegate?.poseDetectionService(self, didFailWithError: error, processingTime: processingTime)
            return
        }
        
        guard let result = result else {
            delegate?.poseDetectionService(self, didFailWithError: nil, processingTime: processingTime)
            return
        }
        
        delegate?.poseDetectionService(self, didDetectPose: result, processingTime: processingTime)
    }
}
