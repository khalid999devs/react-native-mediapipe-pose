import ExpoModulesCore
import AVFoundation
import UIKit
import MediaPipeTasksVision

enum DeviceTier: String, CaseIterable {
  case high = "high"       // iPhone 12+, iPad Pro
  case medium = "medium"   // iPhone X-11, iPad Air
  case low = "low"         // iPhone 8-, older iPads
  case unknown = "unknown"
  
  var recommendedFPS: Int {
    switch self {
    case .high: return 60
    case .medium: return 30
    case .low: return 15
    case .unknown: return 30
    }
  }
  
  var maxResolution: AVCaptureSession.Preset {
    switch self {
    case .high: return .hd1920x1080
    case .medium: return .hd1280x720
    case .low: return .vga640x480
    case .unknown: return .hd1280x720
    }
  }
}

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ReactNativeMediapipePoseView: ExpoView {
  private var captureSession: AVCaptureSession?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var poseOverlayLayer: CAShapeLayer?
  private var currentCameraType: AVCaptureDevice.Position = .back
  private var videoDevice: AVCaptureDevice?
  private var videoInput: AVCaptureDeviceInput?
  private var videoOutput: AVCaptureVideoDataOutput?
  
  // FPS tracking
  private var frameCount = 0
  private var lastFPSTime = CACurrentMediaTime()
  private var currentFPS: Double = 0.0
  private var targetFPS: Int = 30 // Default to 30 FPS
  private var lastFrameTime = CACurrentMediaTime()
  
  // Performance monitoring
  private var fpsHistory: [Double] = []
  private var performanceCheckInterval: TimeInterval = 5.0 // Check every 5 seconds
  private var lastPerformanceCheck = CACurrentMediaTime()
  private var isAutoAdjustEnabled = true
  
  // Device capability detection
  private var deviceTier: DeviceTier = .unknown
  
  // Pose detection
  private var isPoseDetectionEnabled = false
  private var poseDetectionService: PoseDetectionService?
  private let processingQueue = DispatchQueue(label: "pose.processing", qos: .userInitiated)
  
  let onCameraReady = EventDispatcher()
  let onError = EventDispatcher()
  let onFrameProcessed = EventDispatcher()
  let onPoseDetected = EventDispatcher()
  let onDeviceCapability = EventDispatcher()
  let onPoseServiceLog = EventDispatcher()
  let onPoseServiceError = EventDispatcher()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    detectDeviceCapability()
    setupCamera()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
    poseOverlayLayer?.frame = bounds
  }
  
  private func detectDeviceCapability() {
    let _ = UIDevice.current.model // Device model detection logic can be added here
    let systemVersion = UIDevice.current.systemVersion
    let processorCount = ProcessInfo.processInfo.processorCount
    let physicalMemory = ProcessInfo.processInfo.physicalMemory
    
    // Detect device tier based on hardware characteristics
    if #available(iOS 14.0, *) {
      if processorCount >= 6 && physicalMemory >= 4_000_000_000 { // 4GB+ RAM, 6+ cores
        deviceTier = .high
      } else if processorCount >= 4 && physicalMemory >= 3_000_000_000 { // 3GB+ RAM, 4+ cores
        deviceTier = .medium
      } else {
        deviceTier = .low
      }
    } else {
      deviceTier = .low // Older iOS versions get low tier
    }
    
    // Set recommended FPS based on device tier
    targetFPS = deviceTier.recommendedFPS
    
    // Notify frontend about device capabilities
    DispatchQueue.main.async {
      self.onDeviceCapability([
        "deviceTier": self.deviceTier.rawValue,
        "recommendedFPS": self.targetFPS,
        "processorCount": processorCount,
        "physicalMemoryGB": Double(physicalMemory) / 1_000_000_000,
        "systemVersion": systemVersion
      ])
    }
  }
  
  private func setupCamera() {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      
      self.captureSession = AVCaptureSession()
      guard let captureSession = self.captureSession else {
        DispatchQueue.main.async {
          self.onError(["error": "Failed to create capture session"])
        }
        return
      }
      
      // Set session preset based on device capability
      captureSession.sessionPreset = self.deviceTier.maxResolution
      
      guard let camera = self.getCameraDevice(for: self.currentCameraType) else {
        DispatchQueue.main.async {
          #if targetEnvironment(simulator)
          self.onError(["error": "Camera not available in iOS Simulator. Please test on a physical device."])
          #else
          self.onError(["error": "No camera device available for the requested position"])
          #endif
        }
        return
      }
      
      do {
        let input = try AVCaptureDeviceInput(device: camera)
        
        if captureSession.canAddInput(input) {
          captureSession.addInput(input)
          self.videoDevice = camera
          self.videoInput = input
          
          // Setup video output for frame processing
          self.setupVideoOutput()
          
          DispatchQueue.main.async {
            self.setupPreviewLayer()
            captureSession.startRunning()
            self.onCameraReady(["ready": true])
          }
        } else {
          DispatchQueue.main.async {
            self.onError(["error": "Cannot add camera input"])
          }
        }
      } catch {
        DispatchQueue.main.async {
          self.onError(["error": "Failed to create camera input: \(error.localizedDescription)"])
        }
      }
    }
  }
  
  private func setupPreviewLayer() {
    guard let captureSession = captureSession else { return }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer?.videoGravity = .resizeAspectFill
    previewLayer?.frame = bounds
    
    if let previewLayer = previewLayer {
      layer.addSublayer(previewLayer)
    }
    
    // Setup pose overlay layer
    setupPoseOverlayLayer()
  }
  
  private func setupPoseOverlayLayer() {
    poseOverlayLayer = CAShapeLayer()
    poseOverlayLayer?.fillColor = UIColor.clear.cgColor  // Clear fill, only stroke for skeleton
    poseOverlayLayer?.strokeColor = UIColor.cyan.cgColor
    poseOverlayLayer?.lineWidth = 2.0  // Thinner lines like MediaPipe example
    poseOverlayLayer?.frame = bounds
    poseOverlayLayer?.zPosition = 1000 // Ensure it's on top
    
    if let poseOverlayLayer = poseOverlayLayer {
      layer.addSublayer(poseOverlayLayer)
      print("🎨 ReactNativeMediapipePoseView: Pose overlay layer added with frame: \(bounds)")
    }
  }
  
  private func setupVideoOutput() {
    guard let captureSession = captureSession else { return }
    
    videoOutput = AVCaptureVideoDataOutput()
    videoOutput?.setSampleBufferDelegate(self, queue: processingQueue)
    videoOutput?.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]
    
    if captureSession.canAddOutput(videoOutput!) {
      captureSession.addOutput(videoOutput!)
    }
    
    // Initialize pose detection service
    setupPoseDetection()
  }
  
  private func setupPoseDetection() {
    print("🔧 ReactNativeMediapipePoseView: Setting up pose detection service...")
    poseDetectionService = PoseDetectionService(delegate: self)
  }
  
  // MARK: - Pose Detection
  func enablePoseDetection(_ enabled: Bool) {
    isPoseDetectionEnabled = enabled
    print("📹 ReactNativeMediapipePoseView: Pose detection \(enabled ? "enabled" : "disabled")")
    
    // Clear pose overlay when disabled
    if !enabled {
      DispatchQueue.main.async {
        self.poseOverlayLayer?.path = nil
        print("🎨 Pose overlay cleared (detection disabled)")
      }
    }
  }
  
  func setTargetFPS(_ fps: Int) {
    targetFPS = max(1, min(fps, 60)) // Clamp between 1-60 FPS
    print("Target FPS set to: \(targetFPS)")
  }
  
  func setAutoAdjustFPS(_ enabled: Bool) {
    isAutoAdjustEnabled = enabled
    if !enabled {
      fpsHistory.removeAll() // Clear history when disabled
    }
    print("Auto FPS adjustment: \(enabled ? "enabled" : "disabled")")
  }
  
  private func shouldProcessFrame() -> Bool {
    let currentTime = CACurrentMediaTime()
    let targetInterval = 1.0 / Double(targetFPS)
    
    if currentTime - lastFrameTime >= targetInterval {
      lastFrameTime = currentTime
      return true
    }
    return false
  }
  
  private func simulatePoseDetection() -> [[String: Any]] {
    // Simulate 33 pose landmarks (MediaPipe BlazePose format)
    var landmarks: [[String: Any]] = []
    
    for _ in 0..<33 {
      let landmark: [String: Any] = [
        "x": Double.random(in: 0.0...1.0),
        "y": Double.random(in: 0.0...1.0),
        "z": Double.random(in: -0.5...0.5),
        "visibility": Double.random(in: 0.5...1.0)
      ]
      landmarks.append(landmark)
    }
    
    return landmarks
  }
  
  private func calculateFPS() {
    frameCount += 1
    let currentTime = CACurrentMediaTime()
    let deltaTime = currentTime - lastFPSTime
    
    if deltaTime >= 1.0 {
      currentFPS = Double(frameCount) / deltaTime
      frameCount = 0
      lastFPSTime = currentTime
      
      // Add to FPS history for performance monitoring
      fpsHistory.append(currentFPS)
      if fpsHistory.count > 10 { // Keep last 10 FPS readings
        fpsHistory.removeFirst()
      }
      
      DispatchQueue.main.async {
        self.onFrameProcessed([
          "fps": self.currentFPS,
          "frameCount": self.frameCount
        ])
      }
      
      // Check if we need to auto-adjust FPS
      checkPerformanceAndAdjust(currentTime: currentTime)
    }
  }
  
  private func checkPerformanceAndAdjust(currentTime: TimeInterval) {
    guard isAutoAdjustEnabled && currentTime - lastPerformanceCheck >= performanceCheckInterval else { return }
    
    lastPerformanceCheck = currentTime
    
    if fpsHistory.count >= 5 {
      let averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
      let fpsEfficiency = averageFPS / Double(targetFPS)
      
      // If consistently dropping below 80% of target FPS, reduce target
      if fpsEfficiency < 0.8 && targetFPS > 15 {
        let newTargetFPS = max(15, targetFPS - 5)
        print("Performance auto-adjustment: Reducing target FPS from \(targetFPS) to \(newTargetFPS)")
        setTargetFPS(newTargetFPS)
        
        DispatchQueue.main.async {
          self.onFrameProcessed([
            "fps": self.currentFPS,
            "frameCount": self.frameCount,
            "autoAdjusted": true,
            "newTargetFPS": newTargetFPS,
            "reason": "Performance optimization"
          ])
        }
      }
      // If consistently above 95% and below max recommended, try increasing
      else if fpsEfficiency > 0.95 && targetFPS < deviceTier.recommendedFPS {
        let newTargetFPS = min(deviceTier.recommendedFPS, targetFPS + 5)
        print("Performance auto-adjustment: Increasing target FPS from \(targetFPS) to \(newTargetFPS)")
        setTargetFPS(newTargetFPS)
        
        DispatchQueue.main.async {
          self.onFrameProcessed([
            "fps": self.currentFPS,
            "frameCount": self.frameCount,
            "autoAdjusted": true,
            "newTargetFPS": newTargetFPS,
            "reason": "Performance headroom available"
          ])
        }
      }
    }
  }
  
  private func getCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    let deviceTypes: [AVCaptureDevice.DeviceType] = [
      .builtInWideAngleCamera,
      .builtInDualCamera,
      .builtInTrueDepthCamera
    ]
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: deviceTypes,
      mediaType: .video,
      position: position
    )
    
    let device = discoverySession.devices.first
    
    // Check if we're running in simulator
    #if targetEnvironment(simulator)
    if device == nil {
      print("Camera not available in iOS Simulator. Please test on a physical device.")
    }
    #endif
    
    return device
  }
  
  func setCameraType(_ position: AVCaptureDevice.Position) {
    guard currentCameraType != position else { return }
    currentCameraType = position
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.switchCameraInternal()
    }
  }
  
  func switchCamera() {
    let newPosition: AVCaptureDevice.Position = currentCameraType == .back ? .front : .back
    setCameraType(newPosition)
  }
  
  private func switchCameraInternal() {
    guard let captureSession = captureSession,
          let currentInput = videoInput else { return }
    
    captureSession.beginConfiguration()
    captureSession.removeInput(currentInput)
    
    guard let newCamera = getCameraDevice(for: currentCameraType) else {
      DispatchQueue.main.async {
        self.onError(["error": "Cannot find camera for position"])
      }
      captureSession.commitConfiguration()
      return
    }
    
    do {
      let newInput = try AVCaptureDeviceInput(device: newCamera)
      
      if captureSession.canAddInput(newInput) {
        captureSession.addInput(newInput)
        videoDevice = newCamera
        videoInput = newInput
      } else {
        // Revert to previous input
        captureSession.addInput(currentInput)
        DispatchQueue.main.async {
          self.onError(["error": "Cannot add new camera input"])
        }
      }
    } catch {
      // Revert to previous input
      captureSession.addInput(currentInput)
      DispatchQueue.main.async {
        self.onError(["error": "Failed to create new camera input: \(error.localizedDescription)"])
      }
    }
    
    captureSession.commitConfiguration()
  }
  
  deinit {
    captureSession?.stopRunning()
    captureSession = nil
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ReactNativeMediapipePoseView: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // Always calculate FPS for monitoring
    calculateFPS()
    
    // Only process frames at target FPS rate
    guard shouldProcessFrame() else { return }
    
    if isPoseDetectionEnabled {
      print("📹 ReactNativeMediapipePoseView: Processing frame for pose detection...")
      // Get current timestamp for MediaPipe
      let currentTimeMs = Int(Date().timeIntervalSince1970 * 1000)
      
      // Determine image orientation based on device orientation
      let orientation: UIImage.Orientation = .up
      
      // Pass frame to MediaPipe pose detection on background queue
      processingQueue.async { [weak self] in
        self?.poseDetectionService?.detectAsync(
          sampleBuffer: sampleBuffer,
          orientation: orientation,
          timeStamps: currentTimeMs
        )
      }
    }
  }
}

// MARK: - PoseDetectionServiceDelegate
extension ReactNativeMediapipePoseView: PoseDetectionServiceDelegate {
  func poseDetectionService(_ service: PoseDetectionService, didDetectPose result: PoseLandmarkerResult, processingTime: Double) {
    // Convert MediaPipe result to our format
    let landmarks = convertPoseLandmarkerResult(result)
    print("🎯 ReactNativeMediapipePoseView: Pose detected with \(landmarks.count) landmarks, processing time: \(String(format: "%.1f", processingTime))ms")
    
    // Draw pose landmarks on the overlay
    if let poseResult = result.landmarks.first {
      drawPoseLandmarks(poseResult)
    }
    
    DispatchQueue.main.async {
      self.onPoseDetected([
        "landmarks": landmarks,
        "processingTime": processingTime,
        "timestamp": CACurrentMediaTime(),
        "deviceTier": self.deviceTier.rawValue,
        "confidence": result.landmarks.first?.first?.visibility?.doubleValue ?? 0.0
      ])
    }
  }
  
  func poseDetectionService(_ service: PoseDetectionService, didFailWithError error: Error?, processingTime: Double) {
    print("❌ ReactNativeMediapipePoseView: Pose detection failed: \(error?.localizedDescription ?? "Unknown error"), processing time: \(String(format: "%.1f", processingTime))ms")
    DispatchQueue.main.async {
      self.onPoseServiceError([
        "error": error?.localizedDescription ?? "Unknown error",
        "processingTime": processingTime
      ])
    }
  }
  
  func poseDetectionService(_ service: PoseDetectionService, didLogMessage message: String, level: String) {
    DispatchQueue.main.async {
      self.onPoseServiceLog([
        "message": message,
        "level": level,
        "timestamp": Date().timeIntervalSince1970
      ])
    }
  }
  
  private func convertPoseLandmarkerResult(_ result: PoseLandmarkerResult) -> [[String: Any]] {
    guard let landmarks = result.landmarks.first else { return [] }
    
    return landmarks.map { landmark in
      return [
        "x": landmark.x,
        "y": landmark.y,
        "z": landmark.z,
        "visibility": landmark.visibility?.doubleValue ?? 0.0
      ]
    }
  }
  
  private func drawPoseLandmarks(_ landmarks: [NormalizedLandmark]) {
    print("🎨 ReactNativeMediapipePoseView: Drawing \(landmarks.count) landmarks")
    
    let path = UIBezierPath()
    let viewSize = bounds.size
    var visibleLandmarks = 0
    
    print("🎨 View size: \(viewSize)")
    
    // Get the actual video preview rect to properly scale coordinates
    let videoRect = getVideoPreviewRect()
    print("🎨 Video preview rect: \(videoRect)")
    
    // Draw landmarks as small circles (like MediaPipe example)
    for (index, landmark) in landmarks.enumerated() {
      let visibility = landmark.visibility?.doubleValue ?? 0.0
      if visibility > 0.5 { // Only draw visible landmarks
        visibleLandmarks += 1
        
        // Transform normalized coordinates to screen coordinates
        let transformedPoint = transformNormalizedPoint(
          x: landmark.x, 
          y: landmark.y, 
          videoRect: videoRect
        )
        
        print("🎯 Landmark \(index): normalized(\(landmark.x), \(landmark.y)) -> screen(\(transformedPoint.x), \(transformedPoint.y)) visibility: \(visibility)")
        
        // Draw small filled circles for landmarks (like MediaPipe example)
        let circle = UIBezierPath(arcCenter: transformedPoint, radius: 4, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        path.append(circle)
      }
    }
    
    print("🎨 Drawing \(visibleLandmarks) visible landmarks")
    
    // Draw pose connections (skeleton)
    drawPoseConnections(landmarks, path: path, videoRect: videoRect)
    
    DispatchQueue.main.async {
      self.poseOverlayLayer?.path = path.cgPath
      self.poseOverlayLayer?.strokeColor = UIColor.cyan.cgColor
      self.poseOverlayLayer?.fillColor = UIColor.cyan.cgColor  // Fill for landmark circles
      self.poseOverlayLayer?.lineWidth = 2.0  // Match MediaPipe example
      print("🎨 Pose path updated on main thread")
    }
  }
  
  private func transformNormalizedPoint(x: Float, y: Float, videoRect: CGRect) -> CGPoint {
    var transformedX = CGFloat(x)
    var transformedY = CGFloat(y)
    
    // Mirror horizontally for front camera (selfie mode)
    if currentCameraType == .front {
      transformedX = 1.0 - transformedX
    }
    
    // Convert to screen coordinates within video rect
    let screenX = videoRect.origin.x + transformedX * videoRect.width
    let screenY = videoRect.origin.y + transformedY * videoRect.height
    
    return CGPoint(x: screenX, y: screenY)
  }
  
  private func getVideoPreviewRect() -> CGRect {
    guard let previewLayer = previewLayer else {
      return bounds // Fallback to full bounds
    }
    
    // Calculate the actual video preview area within the layer
    // This accounts for aspect ratio scaling
    let layerBounds = previewLayer.bounds
    let videoGravity = previewLayer.videoGravity
    
    if videoGravity == .resizeAspectFill {
      // For aspect fill, the video covers the entire bounds
      return layerBounds
    } else if videoGravity == .resizeAspect {
      // For aspect fit, we need to calculate the actual video rect
      // This is more complex and would require video dimensions
      // For now, use full bounds as approximation
      return layerBounds
    } else {
      // For resize (stretch), use full bounds
      return layerBounds
    }
  }
  
  private func drawPoseConnections(_ landmarks: [NormalizedLandmark], path: UIBezierPath, videoRect: CGRect) {
    // MediaPipe Pose connections - exact same as MediaPipe pose example
    let connections: [(Int, Int)] = [
      // Face connections
      (0, 1), (1, 2), (2, 3), (3, 7),
      (0, 4), (4, 5), (5, 6), (6, 8),
      (9, 10), // mouth
      
      // Body connections
      (11, 12), // shoulders
      (11, 13), (13, 15), // left arm
      (12, 14), (14, 16), // right arm
      (11, 23), (12, 24), // torso
      (23, 24), // hips
      
      // Left leg
      (23, 25), (25, 27), (27, 29), (29, 31),
      (27, 31), // left foot
      
      // Right leg
      (24, 26), (26, 28), (28, 30), (30, 32),
      (28, 32), // right foot
      
      // Hand landmarks (optional, can be enabled/disabled)
      (15, 17), (15, 19), (15, 21), (17, 19), // left hand
      (16, 18), (16, 20), (16, 22), (18, 20)  // right hand
    ]
    
    var connectionsDrawn = 0
    
    for (startIdx, endIdx) in connections {
      if startIdx < landmarks.count && endIdx < landmarks.count {
        let startLandmark = landmarks[startIdx]
        let endLandmark = landmarks[endIdx]
        
        let startVisibility = startLandmark.visibility?.doubleValue ?? 0.0
        let endVisibility = endLandmark.visibility?.doubleValue ?? 0.0
        
        // Only draw if both landmarks are visible (same threshold as MediaPipe example)
        if startVisibility > 0.5 && endVisibility > 0.5 {
          let startPoint = transformNormalizedPoint(
            x: startLandmark.x,
            y: startLandmark.y,
            videoRect: videoRect
          )
          let endPoint = transformNormalizedPoint(
            x: endLandmark.x,
            y: endLandmark.y,
            videoRect: videoRect
          )
          
          path.move(to: startPoint)
          path.addLine(to: endPoint)
          connectionsDrawn += 1
        }
      }
    }
    
    print("🦴 Drew \(connectionsDrawn) pose connections")
  }
}
