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
  
  // Optimized pose rendering layers for maximum smoothness
  private var activeConnectionLayer: CAShapeLayer?
  private var activeLandmarkLayer: CAShapeLayer?
  
  private var currentCameraType: AVCaptureDevice.Position = .front
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
  
  // Performance optimization properties
  private var enablePoseDataStreaming: Bool = false // Default to false for better performance
  private var poseDataThrottleMs: Int = 100 // Throttle pose data events to reduce bridge overhead
  private var enableDetailedLogs: Bool = false // Control detailed logging for performance
  private var lastPoseDataSentTime: TimeInterval = 0 // Track when pose data was last sent
  
  // FPS optimization properties
  private var lastReportedFPS: Double = 0 // Track last reported FPS to avoid duplicate sends
  private var fpsChangeThreshold: Double = 2.0 // Only report FPS changes > 2 FPS
  private var lastFPSReportTime: TimeInterval = 0 // Track when FPS was last reported
  private var fpsReportThrottleMs: Double = 500 // Minimum 500ms between FPS reports
  
  private var poseDetectionService: PoseDetectionService?
  private let processingQueue = DispatchQueue(label: "pose.processing", qos: .userInitiated)
  
  let onCameraReady = EventDispatcher()
  let onError = EventDispatcher()
  let onFrameProcessed = EventDispatcher()
  let onPoseDetected = EventDispatcher()
  let onDeviceCapability = EventDispatcher()
  let onPoseServiceLog = EventDispatcher()
  let onPoseServiceError = EventDispatcher()
  let onGPUStatus = EventDispatcher() // New event for GPU/CPU status

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
    
    // Update optimized layer frames
    activeConnectionLayer?.frame = bounds
    activeLandmarkLayer?.frame = bounds
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
    
    // Set video orientation to match device orientation
    if let connection = previewLayer?.connection, connection.isVideoOrientationSupported {
      connection.videoOrientation = .portrait
      if enableDetailedLogs {
        print("📱 Set preview layer video orientation to portrait")
      }
    }
    
    if let previewLayer = previewLayer {
      layer.addSublayer(previewLayer)
    }
    
    // Setup pose overlay layer
    setupPoseOverlayLayer()
  }
  
  private func setupPoseOverlayLayer() {
    poseOverlayLayer = CAShapeLayer()
    poseOverlayLayer?.fillColor = UIColor.clear.cgColor
    poseOverlayLayer?.frame = bounds
    poseOverlayLayer?.zPosition = 1000 // Ensure it's on top
    
    // Create optimized single-layer system for maximum performance
    setupOptimizedPoseLayers()
    
    if let poseOverlayLayer = poseOverlayLayer {
      layer.addSublayer(poseOverlayLayer)
      if enableDetailedLogs {
        print("🎨 ReactNativeMediapipePoseView: Optimized pose overlay layer added with frame: \(bounds)")
      }
    }
  }
  
  private func setupOptimizedPoseLayers() {
    // Create high-performance layers with optimized properties
    activeConnectionLayer = createOptimizedConnectionLayer()
    activeLandmarkLayer = createOptimizedLandmarkLayer()
    
    // Pre-configure layer properties once for better performance
    activeConnectionLayer?.strokeColor = UIColor.systemGreen.cgColor
    activeConnectionLayer?.opacity = 0.8
    activeLandmarkLayer?.fillColor = UIColor.systemOrange.cgColor
    activeLandmarkLayer?.opacity = 0.9
    
    // Add layers to the overlay
    if let poseOverlay = poseOverlayLayer {
      if let activeConnection = activeConnectionLayer {
        poseOverlay.addSublayer(activeConnection)
      }
      if let activeLandmark = activeLandmarkLayer {
        poseOverlay.addSublayer(activeLandmark)
      }
    }
  }
  
  private func setupDoubleBufferedLayers() {
    // Legacy method - now using optimized single-layer approach
    setupOptimizedPoseLayers()
  }
  
  private func createOptimizedConnectionLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.strokeColor = UIColor.systemGreen.cgColor
    layer.fillColor = UIColor.clear.cgColor
    layer.lineWidth = 2.0
    layer.lineJoin = .round
    layer.lineCap = .round
    layer.opacity = 0.8
    
    // Performance optimizations for real-time updates
    layer.shouldRasterize = false // Disable rasterization for dynamic content
    layer.drawsAsynchronously = false // Synchronous drawing for immediate response
    
    return layer
  }
  
  private func createOptimizedLandmarkLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.fillColor = UIColor.systemOrange.cgColor
    layer.strokeColor = UIColor.white.cgColor
    layer.lineWidth = 1.5
    layer.opacity = 0.9
    
    // Performance optimizations for real-time updates
    layer.shouldRasterize = false // Disable rasterization for dynamic content
    layer.drawsAsynchronously = false // Synchronous drawing for immediate response
    
    return layer
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
      
      // Set video orientation for output to match preview
      if let connection = videoOutput?.connection(with: .video),
         connection.isVideoOrientationSupported {
        connection.videoOrientation = .portrait
        if enableDetailedLogs {
          print("📱 Set video output orientation to portrait")
        }
      }
    }
    
    // Initialize pose detection service
    setupPoseDetection()
  }
  
  private func setupPoseDetection() {
    if enableDetailedLogs {
      print("🔧 ReactNativeMediapipePoseView: Setting up pose detection service...")
    }
    poseDetectionService = PoseDetectionService(delegate: self)
    
    // Report GPU/CPU status after initialization
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self, let service = self.poseDetectionService else { return }
      
      let isUsingGPU = service.isUsingGPU()
      let currentDelegate = service.getCurrentDelegate()
      
      self.onGPUStatus([
        "isUsingGPU": isUsingGPU,
        "delegate": currentDelegate,
        "deviceTier": self.deviceTier.rawValue,
        "maxAccuracy": isUsingGPU,
        "processingUnit": isUsingGPU ? "Neural Engine/GPU" : "CPU"
      ])
      
      if enableDetailedLogs {
        print("🚀 ReactNativeMediapipePoseView: Pose detection using \(currentDelegate) for \(isUsingGPU ? "maximum accuracy" : "compatibility")")
      }
    }
  }
  
  // MARK: - Pose Detection
  func enablePoseDetection(_ enabled: Bool) {
    isPoseDetectionEnabled = enabled
    if enableDetailedLogs {
      print("📹 ReactNativeMediapipePoseView: Pose detection \(enabled ? "enabled" : "disabled")")
    }
    
    // Optimized pose overlay management for smoothness
    if !enabled {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        
        // Fast, smooth fade out for professional experience
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2) // Quick fade out
        CATransaction.setCompletionBlock {
          // Clear paths after fade completes
          self.activeConnectionLayer?.path = nil
          self.activeLandmarkLayer?.path = nil
        }
        
        self.activeConnectionLayer?.opacity = 0.0
        self.activeLandmarkLayer?.opacity = 0.0
        
        CATransaction.commit()
        
        if self.enableDetailedLogs {
          print("🎨 Pose overlay optimized fade out (detection disabled)")
        }
      }
    } else {
      // Immediate restore for responsiveness
      DispatchQueue.main.async { [weak self] in
        self?.activeConnectionLayer?.opacity = 0.8
        self?.activeLandmarkLayer?.opacity = 0.9
      }
    }
  }
  
  func setTargetFPS(_ fps: Int) {
    targetFPS = max(1, min(fps, 60)) // Clamp between 1-60 FPS
    if enableDetailedLogs {
      print("Target FPS set to: \(targetFPS)")
    }
  }
  
  func setAutoAdjustFPS(_ enabled: Bool) {
    isAutoAdjustEnabled = enabled
    if !enabled {
      fpsHistory.removeAll() // Clear history when disabled
    }
    if enableDetailedLogs {
      print("Auto FPS adjustment: \(enabled ? "enabled" : "disabled")")
    }
  }
  
  func setEnablePoseDataStreaming(_ enabled: Bool) {
    enablePoseDataStreaming = enabled
  }
  
  func setPoseDataThrottleMs(_ throttleMs: Int) {
    poseDataThrottleMs = max(16, throttleMs)
  }
  
  func setEnableDetailedLogs(_ enabled: Bool) {
    enableDetailedLogs = enabled
  }
  
  func setFPSChangeThreshold(_ threshold: Double) {
    fpsChangeThreshold = max(0.5, threshold)
  }
  
  func setFPSReportThrottleMs(_ throttleMs: Double) {
    fpsReportThrottleMs = max(100, throttleMs)
  }
  
  func getGPUStatus() -> [String: Any] {
    guard let service = poseDetectionService else {
      return [
        "isUsingGPU": false,
        "delegate": "Unknown",
        "deviceTier": deviceTier.rawValue,
        "maxAccuracy": false,
        "processingUnit": "Unknown"
      ]
    }
    
    let isUsingGPU = service.isUsingGPU()
    return [
      "isUsingGPU": isUsingGPU,
      "delegate": service.getCurrentDelegate(),
      "deviceTier": deviceTier.rawValue,
      "maxAccuracy": isUsingGPU,
      "processingUnit": isUsingGPU ? "Neural Engine/GPU" : "CPU"
    ]
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
      
      // Only send FPS data if there's a significant change or enough time has passed
      let timeSinceLastReport = (currentTime - lastFPSReportTime) * 1000 // Convert to ms
      let fpsChange = abs(currentFPS - lastReportedFPS)
      
      if fpsChange >= fpsChangeThreshold || timeSinceLastReport >= fpsReportThrottleMs {
        lastReportedFPS = currentFPS
        lastFPSReportTime = currentTime
        
        DispatchQueue.main.async {
          self.onFrameProcessed([
            "fps": self.currentFPS,
            "frameCount": self.frameCount
          ])
        }
      }
      
      // Check if we need to auto-adjust FPS (this always runs for internal optimization)
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
        if enableDetailedLogs {
          print("Performance auto-adjustment: Reducing target FPS from \(targetFPS) to \(newTargetFPS)")
        }
        setTargetFPS(newTargetFPS)
        
        // Always send auto-adjustment events as they're critical performance updates
        DispatchQueue.main.async {
          self.onFrameProcessed([
            "fps": self.currentFPS,
            "frameCount": self.frameCount,
            "autoAdjusted": true,
            "newTargetFPS": newTargetFPS,
            "reason": "Performance optimization"
          ])
        }
        
        // Update tracking to avoid duplicate regular FPS reports immediately after adjustment
        self.lastReportedFPS = self.currentFPS
        self.lastFPSReportTime = currentTime
      }
      // If consistently above 95% and below max recommended, try increasing
      else if fpsEfficiency > 0.95 && targetFPS < deviceTier.recommendedFPS {
        let newTargetFPS = min(deviceTier.recommendedFPS, targetFPS + 5)
        if enableDetailedLogs {
          print("Performance auto-adjustment: Increasing target FPS from \(targetFPS) to \(newTargetFPS)")
        }
        setTargetFPS(newTargetFPS)
        
        // Always send auto-adjustment events as they're critical performance updates
        DispatchQueue.main.async {
          self.onFrameProcessed([
            "fps": self.currentFPS,
            "frameCount": self.frameCount,
            "autoAdjusted": true,
            "newTargetFPS": newTargetFPS,
            "reason": "Performance headroom available"
          ])
        }
        
        // Update tracking to avoid duplicate regular FPS reports immediately after adjustment
        self.lastReportedFPS = self.currentFPS
        self.lastFPSReportTime = currentTime
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
      if enableDetailedLogs {
        print("📹 ReactNativeMediapipePoseView: Processing frame for pose detection...")
      }
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
    // Guard against processing when detection is disabled to prevent flickering
    guard isPoseDetectionEnabled else { return }
    
    // Convert MediaPipe result to our format for drawing
    let landmarks = convertPoseLandmarkerResult(result)
    
    if enableDetailedLogs {
      print("🎯 ReactNativeMediapipePoseView: Pose detected with \(landmarks.count) landmarks, processing time: \(String(format: "%.1f", processingTime))ms")
    }
    
    // Always draw pose landmarks for visual feedback
    if let poseResult = result.landmarks.first {
      drawPoseLandmarks(poseResult)
    }
    
    // Only send pose data to React Native if streaming is enabled and throttle conditions are met
    if enablePoseDataStreaming {
      let currentTime = CACurrentMediaTime()
      let timeSinceLastSent = (currentTime - lastPoseDataSentTime) * 1000 // Convert to milliseconds
      
      if timeSinceLastSent >= Double(poseDataThrottleMs) {
        lastPoseDataSentTime = currentTime
        
        DispatchQueue.main.async {
          // Send minimal essential data to reduce bridge overhead
          var essentialData: [String: Any] = [
            "landmarks": landmarks,
            "processingTime": processingTime,
            "timestamp": currentTime,
            "confidence": result.landmarks.first?.first?.visibility?.doubleValue ?? 0.0
          ]
          
          // Only include GPU status if detailed mode is enabled to reduce data size
          if self.enableDetailedLogs {
            let gpuStatus = self.getGPUStatus()
            essentialData["deviceTier"] = self.deviceTier.rawValue
            essentialData["gpuAccelerated"] = gpuStatus["isUsingGPU"] as? Bool ?? false
            essentialData["processingUnit"] = gpuStatus["processingUnit"] as? String ?? "Unknown"
            essentialData["delegate"] = gpuStatus["delegate"] as? String ?? "Unknown"
          }
          
          self.onPoseDetected(essentialData)
        }
      }
    }
  }
  
  func poseDetectionService(_ service: PoseDetectionService, didFailWithError error: Error?, processingTime: Double) {
    if enableDetailedLogs {
      print("❌ ReactNativeMediapipePoseView: Pose detection failed: \(error?.localizedDescription ?? "Unknown error"), processing time: \(String(format: "%.1f", processingTime))ms")
    }
    
    // Always send error events as they are important
    DispatchQueue.main.async {
      self.onPoseServiceError([
        "error": error?.localizedDescription ?? "Unknown error",
        "processingTime": processingTime
      ])
    }
  }
  
  func poseDetectionService(_ service: PoseDetectionService, didLogMessage message: String, level: String) {
    // Only send log messages to React Native if detailed logging is enabled to reduce bridge overhead
    if enableDetailedLogs {
      DispatchQueue.main.async {
        self.onPoseServiceLog([
          "message": message,
          "level": level,
          "timestamp": Date().timeIntervalSince1970
        ])
      }
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
    // Pre-calculate video rect once for better performance
    let videoRect = getVideoPreviewRect()
    
    // Create optimized paths for landmarks and connections
    let landmarkPath = UIBezierPath()
    let connectionPath = UIBezierPath()
    var visibleLandmarks = 0
    
    // Draw landmarks as small circles (like MediaPipe example)
    for (_, landmark) in landmarks.enumerated() {
      let visibility = landmark.visibility?.doubleValue ?? 0.0
      if visibility > 0.5 { // Only draw visible landmarks
        visibleLandmarks += 1
        
        // Transform normalized coordinates to screen coordinates
        let transformedPoint = transformNormalizedPoint(
          x: landmark.x, 
          y: landmark.y, 
          videoRect: videoRect
        )
        
        // Draw small circles for landmarks
        let circle = UIBezierPath(arcCenter: transformedPoint, radius: 3, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        landmarkPath.append(circle)
      }
    }
    
    // Draw pose connections (skeleton) - single path creation for better performance
    drawPoseConnections(landmarks, path: connectionPath, videoRect: videoRect)
    
    // Fast, synchronous update for maximum smoothness during movement
    // Only async when absolutely necessary (thread safety)
    if Thread.isMainThread {
      // Direct update for maximum performance when already on main thread
      updatePoseLayersDirectly(landmarkPath: landmarkPath, connectionPath: connectionPath)
    } else {
      // Quick async dispatch only when needed
      DispatchQueue.main.async { [weak self] in
        self?.updatePoseLayersDirectly(landmarkPath: landmarkPath, connectionPath: connectionPath)
      }
    }
    
    if enableDetailedLogs {
      print("🎯 Optimized drawing: \(visibleLandmarks) landmarks")
    }
  }
  
  private func updatePoseLayersDirectly(landmarkPath: UIBezierPath, connectionPath: UIBezierPath) {
    guard isPoseDetectionEnabled else { return }
    
    // High-performance direct layer update with minimal overhead
    CATransaction.begin()
    CATransaction.setDisableActions(true) // Disable implicit animations for instant updates
    CATransaction.setAnimationDuration(0) // Zero animation time for immediate response
    
    // Direct path updates for real-time smoothness
    activeConnectionLayer?.path = connectionPath.cgPath
    activeLandmarkLayer?.path = landmarkPath.cgPath
    
    CATransaction.commit()
  }
  
  private func transformNormalizedPoint(x: Float, y: Float, videoRect: CGRect) -> CGPoint {
    // MediaPipe normalized coordinates are in range [0, 1]
    // x: 0 = left, 1 = right
    // y: 0 = top, 1 = bottom
    
    var transformedX = CGFloat(x)
    let transformedY = CGFloat(y)
    
    // Mirror horizontally for front camera (selfie mode)
    if currentCameraType == .front {
      transformedX = 1.0 - transformedX
    }
    
    // Convert normalized coordinates to view coordinates
    let screenX = videoRect.origin.x + transformedX * videoRect.width
    let screenY = videoRect.origin.y + transformedY * videoRect.height
    
    return CGPoint(x: screenX, y: screenY)
  }
  
  private func getVideoPreviewRect() -> CGRect {
    guard let previewLayer = previewLayer else {
      return bounds
    }
    
    // Get the actual video preview rect within the layer bounds
    let layerBounds = previewLayer.bounds
    
    // For most camera setups with ResizeAspectFill, the video covers the entire bounds
    // but we need to account for the actual camera resolution vs display resolution
    
    if previewLayer.videoGravity == .resizeAspectFill {
      // Video fills entire preview area, may be cropped
      return layerBounds
    } else if previewLayer.videoGravity == .resizeAspect {
      // Video fits within preview area with black bars
      // We need to calculate the actual video rect
      guard let _ = previewLayer.connection,
            let input = captureSession?.inputs.first as? AVCaptureDeviceInput else {
        return layerBounds
      }
      
      // Get video dimensions
      let videoSize = input.device.activeFormat.formatDescription.dimensions
      let videoAspectRatio = CGFloat(videoSize.width) / CGFloat(videoSize.height)
      let layerAspectRatio = layerBounds.width / layerBounds.height
      
      var videoRect: CGRect
      if videoAspectRatio > layerAspectRatio {
        // Video is wider, fit by height
        let scaledWidth = layerBounds.height * videoAspectRatio
        let xOffset = (layerBounds.width - scaledWidth) / 2
        videoRect = CGRect(x: xOffset, y: 0, width: scaledWidth, height: layerBounds.height)
      } else {
        // Video is taller, fit by width
        let scaledHeight = layerBounds.width / videoAspectRatio
        let yOffset = (layerBounds.height - scaledHeight) / 2
        videoRect = CGRect(x: 0, y: yOffset, width: layerBounds.width, height: scaledHeight)
      }
      
      return videoRect
    } else {
      // ResizeResize (stretch) - use full bounds
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
    
    if enableDetailedLogs {
      print("🦴 Drew \(connectionsDrawn) pose connections")
    }
  }
}
