import ExpoModulesCore
import AVFoundation
import UIKit

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
  
  // Pose simulation
  private var isPoseDetectionEnabled = false
  private let processingQueue = DispatchQueue(label: "pose.processing", qos: .userInitiated)
  
  let onCameraReady = EventDispatcher()
  let onError = EventDispatcher()
  let onFrameProcessed = EventDispatcher()
  let onPoseDetected = EventDispatcher()
  let onDeviceCapability = EventDispatcher()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    detectDeviceCapability()
    setupCamera()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
  }
  
  private func detectDeviceCapability() {
    let deviceModel = UIDevice.current.model
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
  }
  
  // MARK: - Pose Detection Simulation
  func enablePoseDetection(_ enabled: Bool) {
    isPoseDetectionEnabled = enabled
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
    
    for i in 0..<33 {
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
      // Simulate pose detection processing time based on device tier
      let processingDelay = getProcessingDelay()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + processingDelay) {
        let simulatedPose = self.simulatePoseDetection()
        self.onPoseDetected([
          "landmarks": simulatedPose,
          "processingTime": processingDelay * 1000, // in milliseconds
          "timestamp": CACurrentMediaTime(),
          "deviceTier": self.deviceTier.rawValue
        ])
      }
    }
  }
  
  private func getProcessingDelay() -> Double {
    // Realistic processing delays based on device capability
    switch deviceTier {
    case .high: return Double.random(in: 0.001...0.003)    // 1-3ms
    case .medium: return Double.random(in: 0.003...0.008)  // 3-8ms
    case .low: return Double.random(in: 0.008...0.015)     // 8-15ms
    case .unknown: return Double.random(in: 0.005...0.010) // 5-10ms
    }
  }
}
