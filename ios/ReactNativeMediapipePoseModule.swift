import ExpoModulesCore
import AVFoundation

public class ReactNativeMediapipePoseModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ReactNativeMediapipePose')` in JavaScript.
    Name("ReactNativeMediapipePose")

    // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
    Constants([
      "PI": Double.pi
    ])

    // Defines event names that the module can send to JavaScript.
    Events("onChange")

    // Function to switch camera type
    AsyncFunction("switchCamera") { (viewTag: Int) in
      DispatchQueue.main.async {
        if let view = self.appContext?.findView(withTag: viewTag, ofType: ReactNativeMediapipePoseView.self) {
          view.switchCamera()
        }
      }
    }

    // Function to check camera permissions
    AsyncFunction("requestCameraPermissions") { () -> Bool in
      return await self.requestCameraPermissions()
    }
    
    // Function to get GPU status
    Function("getGPUStatus") { (viewTag: Int) -> [String: Any] in
      if let view = self.appContext?.findView(withTag: viewTag, ofType: ReactNativeMediapipePoseView.self) {
        return view.getGPUStatus()
      }
      return [:]
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    View(ReactNativeMediapipePoseView.self) {
      // Defines a setter for the `cameraType` prop.
      Prop("cameraType") { (view: ReactNativeMediapipePoseView, cameraType: String) in
        let type: AVCaptureDevice.Position = cameraType == "front" ? .front : .back
        view.setCameraType(type)
      }

      // Defines a setter for the `enablePoseDetection` prop.
      Prop("enablePoseDetection") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.enablePoseDetection(enabled)
      }

      // Defines a setter for the `targetFPS` prop.
      Prop("targetFPS") { (view: ReactNativeMediapipePoseView, fps: Int) in
        view.setTargetFPS(fps)
      }

      // Defines a setter for the `autoAdjustFPS` prop.
      Prop("autoAdjustFPS") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.setAutoAdjustFPS(enabled)
      }

      // Defines a setter for the `enablePoseDataStreaming` prop.
      Prop("enablePoseDataStreaming") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.setEnablePoseDataStreaming(enabled)
      }

      // Defines a setter for the `poseDataThrottleMs` prop.
      Prop("poseDataThrottleMs") { (view: ReactNativeMediapipePoseView, throttleMs: Int) in
        view.setPoseDataThrottleMs(throttleMs)
      }

      // Defines a setter for the `enableDetailedLogs` prop.
      Prop("enableDetailedLogs") { (view: ReactNativeMediapipePoseView, enabled: Bool) in
        view.setEnableDetailedLogs(enabled)
      }

      // Defines a setter for the `fpsChangeThreshold` prop.
      Prop("fpsChangeThreshold") { (view: ReactNativeMediapipePoseView, threshold: Double) in
        view.setFPSChangeThreshold(threshold)
      }

      // Defines a setter for the `fpsReportThrottleMs` prop.
      Prop("fpsReportThrottleMs") { (view: ReactNativeMediapipePoseView, throttleMs: Double) in
        view.setFPSReportThrottleMs(throttleMs)
      }

      Events("onCameraReady", "onError", "onFrameProcessed", "onPoseDetected", "onDeviceCapability", "onPoseServiceLog", "onPoseServiceError", "onGPUStatus")
    }
  }
  
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
