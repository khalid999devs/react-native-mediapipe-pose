import ExpoModulesCore
import AVFoundation
import UIKit

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ReactNativeMediapipePoseView: ExpoView {
  private var captureSession: AVCaptureSession?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var currentCameraType: AVCaptureDevice.Position = .back
  private var videoDevice: AVCaptureDevice?
  private var videoInput: AVCaptureDeviceInput?
  
  let onCameraReady = EventDispatcher()
  let onError = EventDispatcher()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    setupCamera()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
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
      
      captureSession.sessionPreset = .high
      
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
