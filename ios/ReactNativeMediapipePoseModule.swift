import ExpoModulesCore
import AVFoundation

/**
 * ReactNativeMediapipePoseModule
 * React Native module for real-time pose detection using MediaPipe
 * Provides camera control, GPU acceleration, and performance optimization
 */
public class ReactNativeMediapipePoseModule: Module {
  
  public func definition() -> ModuleDefinition {
    Name("ReactNativeMediapipePose")

    Constants([
      "PI": Double.pi
    ])

    Events("onChange")

    // Camera control functions
    AsyncFunction("switchCamera") { (viewTag: Int) in
      DispatchQueue.main.async {
        if let view = self.appContext?.findView(withTag: viewTag, ofType: ReactNativeMediapipePoseView.self) {
          view.switchCamera()
        }
      }
    }

    AsyncFunction("requestCameraPermissions") { () -> Bool in
      return await self.requestCameraPermissions()
    }
    
    Function("getGPUStatus") { (viewTag: Int) -> [String: Any] in
      if let view = self.appContext?.findView(withTag: viewTag, ofType: ReactNativeMediapipePoseView.self) {
        return view.getGPUStatus()
      }
      return [:]
    }

    // Camera view component with pose detection capabilities
    View(ReactNativeMediapipePoseView.self) {
      // Core camera properties
      Prop("cameraType") { (view: ReactNativeMediapipePoseView, cameraType: String) in
        let type: AVCaptureDevice.Position = cameraType == "front" ? .front : .back
        view.setCameraType(type)
      }

      Prop("enablePoseDetection") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.enablePoseDetection(enabled)
      }

      // Performance optimization properties
      Prop("enablePoseDataStreaming") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.setEnablePoseDataStreaming(enabled)
      }

      Prop("poseDataThrottleMs") { (view: ReactNativeMediapipePoseView, throttleMs: Int) in
        view.setPoseDataThrottleMs(throttleMs)
      }

      Prop("enableDetailedLogs") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.setEnableDetailedLogs(enabled)
      }

      // Frame rate control properties
      Prop("targetFPS") { (view: ReactNativeMediapipePoseView, fps: Int) in
        view.setTargetFPS(fps)
      }

      Prop("autoAdjustFPS") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.setAutoAdjustFPS(enabled)
      }
      
      // FPS optimization properties
      Prop("fpsChangeThreshold") { (view: ReactNativeMediapipePoseView, threshold: Double) in
        view.setFPSChangeThreshold(threshold)
      }

      Prop("fpsReportThrottleMs") { (view: ReactNativeMediapipePoseView, throttleMs: Double) in
        view.setFPSReportThrottleMs(throttleMs)
      }

      // Event definitions
      Events("onCameraReady", "onError", "onFrameProcessed", "onPoseDetected", "onDeviceCapability", "onPoseServiceLog", "onPoseServiceError", "onGPUStatus")
    }
  }
  
  /**
   * Request camera permissions asynchronously
   * @returns true if permissions granted, false otherwise
   */
  private func requestCameraPermissions() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .authorized:
      return true
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
      return false
    @unknown default:
      return false
    }
  }
}
