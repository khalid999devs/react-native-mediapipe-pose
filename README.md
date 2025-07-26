# React Native MediaPipe Pose

<div align="center">

[![npm version](https://badge.fury.io/js/react-native-mediapipe-pose.svg)](https://badge.fury.io/js/react-native-mediapipe-pose)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://reactnative.dev/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**React Native module for real-time pose detection using Google's MediaPipe BlazePose**

_Production-ready pose detection with GPU acceleration and automatic hardware optimization_

[Installation](#installation) • [Quick Start](#quick-start) • [API Reference](#api-reference) • [Performance](#performance) • [Examples](#examples)

</div>

## 🚀 Features

### 🎯 **Real-time Pose Detection**

- **MediaPipe BlazePose** - Google's production-grade pose detection model
- **33 Pose Landmarks** - Full body keypoint detection with 3D coordinates
- **GPU Acceleration** - Automatic hardware acceleration with Metal framework
- **High Accuracy** - 0.5 confidence threshold for precise detection
- **Live Streaming** - Optimized for real-time video processing

### ⚡ **Performance Optimization**

- **Automatic GPU/CPU Selection** - Dynamic delegate switching for maximum accuracy
- **Data Streaming Control** - Optional pose data transmission (disabled by default for max performance)
- **Throttling System** - Configurable data throttling to reduce bridge overhead
- **FPS Optimization** - Smart FPS reporting with change threshold detection
- **Memory Efficient** - Minimal memory footprint with efficient processing pipeline

### 🔧 **Advanced Configuration**

- **Detailed Logging Control** - Production-ready logging system (disabled by default)
- **Performance Monitoring** - Real-time processing time and GPU status tracking
- **Device Capability Detection** - Automatic hardware tier classification
- **Auto FPS Adjustment** - Dynamic frame rate optimization based on device performance
- **Error Handling** - Comprehensive error reporting and recovery mechanisms

### 📱 **Camera Management**

- **Dual Camera Support** - Front/back camera switching
- **Permission Handling** - Automatic iOS camera permission management
- **Custom Styling** - Fully customizable camera view
- **Orientation Support** - Proper handling of device orientation changes

### 🚧 **Platform Support**

- **iOS** - Fully implemented with MediaPipe BlazePose
- **Android** - In development (currently under active development)
- **Web** - Basic camera support (pose detection coming soon)

## 📦 Installation

### Prerequisites

- React Native >= 0.72
- Expo SDK >= 53
- iOS >= 12.0 (for iOS development)
- Xcode >= 14 (for iOS development)

### Install Package

```bash
npm install react-native-mediapipe-pose
# or
yarn add react-native-mediapipe-pose
```

### iOS Setup

⚠️ **CRITICAL: Manual Configuration Required**

Your app will crash without these steps. The package cannot automatically configure these settings for security reasons.

#### 1. Camera Permissions (REQUIRED)

Add camera permission to your app's `ios/YourAppName/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for pose detection</string>
```

**Alternative descriptions you can use:**

```xml
<!-- For fitness apps -->
<string>Camera access is required for real-time pose tracking and exercise analysis</string>

<!-- For AR/entertainment apps -->
<string>Camera access enables pose detection for interactive experiences</string>

<!-- Generic -->
<string>This app uses the camera to detect and analyze human poses in real-time</string>
```

#### 2. Minimum iOS Version (REQUIRED)

Ensure your app targets **iOS 13.0+** (MediaPipe requirement):

**In `ios/YourApp.xcodeproj`:**

1. Select your project in Xcode
2. Go to Build Settings → Deployment Target
3. Set **iOS Deployment Target** to `13.0` or higher

**In `package.json`:**

```json
{
  "engines": {
    "ios": ">=13.0"
  }
}
```

#### 3. iOS Dependencies (AUTO-INSTALLED)

iOS dependencies are automatically installed when you build your app. However, if you encounter issues, you can manually run:

```bash
cd ios
pod install
cd ..
```

**Note**: Modern React Native (0.72+) and Expo automatically handle pod installation during the build process.

#### 4. Performance Optimization (RECOMMENDED)

For better camera performance, add to `ios/YourAppName/Info.plist`:

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

#### 5. Orientation Support (OPTIONAL)

If you want to support different orientations, configure in `ios/YourAppName/Info.plist`:

```xml
<!-- For iPhone - Portrait only (recommended for pose detection) -->
<key>UISupportedInterfaceOrientations</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
</array>

<!-- For iPad - All orientations -->
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
  <string>UIInterfaceOrientationPortraitUpsideDown</string>
  <string>UIInterfaceOrientationLandscapeLeft</string>
  <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

#### 6. MediaPipe Model (AUTO-INCLUDED)

The MediaPipe pose detection model (`pose_landmarker_full.task`) is automatically included with the package. No manual download required.

#### 7. Complete Info.plist Example

Your `ios/YourAppName/Info.plist` should include at minimum:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Your existing keys... -->

  <!-- REQUIRED: Camera permission -->
  <key>NSCameraUsageDescription</key>
  <string>This app needs camera access for pose detection</string>

  <!-- REQUIRED: Minimum iOS version -->
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>

  <!-- RECOMMENDED: Performance optimization -->
  <key>CADisableMinimumFrameDurationOnPhone</key>
  <true/>

  <!-- RECOMMENDED: Portrait orientation for best pose detection -->
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
  </array>

  <!-- Your other existing keys... -->
</dict>
</plist>
```

#### 8. Verification Steps

After configuration, verify your setup:

1. **Build and run** your app on a physical iOS device
2. **Check camera permission** - app should prompt for camera access
3. **Test pose detection** - camera should display with pose overlay
4. **Check console logs** - look for MediaPipe initialization messages

#### 9. Common Issues & Solutions

**App crashes immediately:**

- ✅ Check that `NSCameraUsageDescription` is added to Info.plist
- ✅ Ensure iOS deployment target is 13.0+
- ✅ Try cleaning build: `npx expo run:ios --clear`
- ✅ If issues persist, manually run `cd ios && pod install`

**Camera permission denied:**

- ✅ Add proper `NSCameraUsageDescription`
- ✅ Manually enable camera permission in iOS Settings → Privacy → Camera

**Pose detection not working:**

- ✅ Test on physical device (camera not available in simulator)
- ✅ Ensure good lighting conditions
- ✅ Check that `enablePoseDetection={true}`

**Performance issues:**

- ✅ Add `CADisableMinimumFrameDurationOnPhone` to Info.plist
- ✅ Set `enablePoseDataStreaming={false}` for production
- ✅ Use `autoAdjustFPS={true}` for device optimization

### Android Setup

**Note: Android support is currently under development and not yet available.**

Android implementation is in active development. Follow our progress:

- MediaPipe Android integration
- Camera2 API implementation
- GPU acceleration support
- Performance optimization

Expected Android support in upcoming releases.

## 🚀 Quick Start

### Basic Implementation

```tsx
import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import ReactNativeMediapipePose, {
  ReactNativeMediapipePoseView,
  PoseDetectionResult,
  CameraType,
  DeviceCapability,
  FrameProcessingInfo,
} from 'react-native-mediapipe-pose';

export default function App() {
  const [cameraType, setCameraType] = useState<CameraType>('front');
  const [isPoseDetectionEnabled, setIsPoseDetectionEnabled] = useState(false);
  const [fps, setFps] = useState<number>(0);

  // Request camera permissions
  const requestPermissions = async () => {
    try {
      const granted = await ReactNativeMediapipePose.requestCameraPermissions();
      if (!granted) {
        Alert.alert(
          'Camera Permission Required',
          'This app requires camera access to detect poses.'
        );
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to request camera permissions');
    }
  };

  const handlePoseDetected = (event: { nativeEvent: PoseDetectionResult }) => {
    const { landmarks, processingTime, confidence } = event.nativeEvent;
    console.log(
      `Detected ${landmarks.length} landmarks in ${processingTime}ms`
    );
  };

  const handleFrameProcessed = (event: {
    nativeEvent: FrameProcessingInfo;
  }) => {
    setFps(Math.round(event.nativeEvent.fps));
  };

  const handleDeviceCapability = (event: { nativeEvent: DeviceCapability }) => {
    const { deviceTier, recommendedFPS } = event.nativeEvent;
    console.log(`Device: ${deviceTier}, Recommended FPS: ${recommendedFPS}`);
  };

  const handleGPUStatus = (event: { nativeEvent: any }) => {
    const { isUsingGPU, processingUnit } = event.nativeEvent;
    console.log(
      `GPU Acceleration: ${isUsingGPU ? 'Enabled' : 'Disabled'} (${processingUnit})`
    );
  };

  const switchCamera = () => {
    // Enhanced camera switching with full refresh to prevent coordinate system issues
    const wasEnabled = isPoseDetectionEnabled;
    setIsPoseDetectionEnabled(false); // Temporarily disable

    // Switch camera type
    setCameraType((current) => (current === 'back' ? 'front' : 'back'));

    // Re-enable pose detection after brief delay for proper initialization
    setTimeout(() => {
      if (wasEnabled) {
        setIsPoseDetectionEnabled(true);
      }
    }, 100);
  };

  React.useEffect(() => {
    requestPermissions();
  }, []);

  return (
    <View style={styles.container}>
      <ReactNativeMediapipePoseView
        key={`camera-${cameraType}`} // Force re-render on camera switch
        style={styles.camera}
        cameraType={cameraType}
        enablePoseDetection={isPoseDetectionEnabled}
        enablePoseDataStreaming={true} // Enable to receive pose data
        targetFPS={30}
        autoAdjustFPS={true}
        onCameraReady={(event) =>
          console.log('Camera ready:', event.nativeEvent.ready)
        }
        onError={(event) =>
          Alert.alert('Camera Error', event.nativeEvent.error)
        }
        onPoseDetected={handlePoseDetected}
        onFrameProcessed={handleFrameProcessed}
        onDeviceCapability={handleDeviceCapability}
        onGPUStatus={handleGPUStatus}
      />

      {/* Simple UI overlay showing FPS */}
      <View style={styles.overlay}>
        <Text style={styles.fpsText}>FPS: {fps}</Text>
        <TouchableOpacity style={styles.button} onPress={switchCamera}>
          <Text style={styles.buttonText}>Switch Camera</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, isPoseDetectionEnabled && styles.buttonActive]}
          onPress={() => setIsPoseDetectionEnabled(!isPoseDetectionEnabled)}
        >
          <Text style={styles.buttonText}>
            {isPoseDetectionEnabled ? 'Stop Pose' : 'Start Pose'}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camera: {
    flex: 1,
  },
  overlay: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  fpsText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  button: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    padding: 10,
    borderRadius: 8,
  },
  buttonActive: {
    backgroundColor: 'rgba(76, 175, 80, 0.8)',
  },
  buttonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
});
```

### Performance Optimized Setup

```tsx
import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import ReactNativeMediapipePose, {
  ReactNativeMediapipePoseView,
  DeviceCapability,
  FrameProcessingInfo,
} from 'react-native-mediapipe-pose';

export default function OptimizedPoseDetection() {
  const [deviceCapability, setDeviceCapability] =
    useState<DeviceCapability | null>(null);
  const [fps, setFps] = useState<number>(0);
  const [targetFPS, setTargetFPS] = useState<number>(30);
  const [autoAdjustFPS, setAutoAdjustFPS] = useState<boolean>(true);
  const [enablePoseDataStreaming, setEnablePoseDataStreaming] =
    useState<boolean>(false);
  const [showPerformanceControls, setShowPerformanceControls] =
    useState<boolean>(false);

  const handleDeviceCapability = (event: { nativeEvent: DeviceCapability }) => {
    const capability = event.nativeEvent;
    setDeviceCapability(capability);
    setTargetFPS(capability.recommendedFPS); // Use device-recommended FPS
  };

  const handleFrameProcessed = (event: {
    nativeEvent: FrameProcessingInfo;
  }) => {
    const { fps: currentFps, autoAdjusted, newTargetFPS } = event.nativeEvent;
    setFps(Math.round(currentFps));

    if (autoAdjusted && newTargetFPS) {
      setTargetFPS(newTargetFPS);
      console.log(`Auto-adjusted FPS to ${newTargetFPS}`);
    }
  };

  const handleGPUStatus = (event: { nativeEvent: any }) => {
    const { isUsingGPU, delegate, deviceTier } = event.nativeEvent;
    console.log(
      `GPU: ${isUsingGPU}, Delegate: ${delegate}, Device: ${deviceTier}`
    );
  };

  return (
    <View style={styles.container}>
      <ReactNativeMediapipePoseView
        key={`camera-optimized-${Date.now()}`} // Ensure clean re-renders
        style={styles.camera}
        enablePoseDetection={true}
        // Performance optimizations (recommended for production)
        enablePoseDataStreaming={enablePoseDataStreaming} // Toggle data streaming
        enableDetailedLogs={false} // Disable for production
        poseDataThrottleMs={100} // Throttle data updates
        fpsChangeThreshold={2.0} // Only report significant FPS changes
        fpsReportThrottleMs={500} // Throttle FPS reports
        // Auto performance adjustment
        autoAdjustFPS={autoAdjustFPS} // Enable automatic FPS optimization
        targetFPS={targetFPS} // Dynamic target based on device
        onFrameProcessed={handleFrameProcessed}
        onDeviceCapability={handleDeviceCapability}
        onGPUStatus={handleGPUStatus}
        onPoseDetected={(event) => {
          if (enablePoseDataStreaming) {
            const { landmarks, processingTime } = event.nativeEvent;
            console.log(
              `Pose: ${landmarks.length} landmarks, ${processingTime}ms`
            );
          }
        }}
      />

      {/* Performance Controls Overlay */}
      <View style={styles.performanceOverlay}>
        <Text style={styles.performanceText}>
          FPS: {fps} | Target: {targetFPS} | Device:{' '}
          {deviceCapability?.deviceTier?.toUpperCase()}
        </Text>

        <TouchableOpacity
          style={styles.toggleButton}
          onPress={() => setShowPerformanceControls(!showPerformanceControls)}
        >
          <Text style={styles.toggleButtonText}>Performance Controls</Text>
        </TouchableOpacity>

        {showPerformanceControls && (
          <View style={styles.controlsPanel}>
            <TouchableOpacity
              style={[
                styles.controlButton,
                enablePoseDataStreaming && styles.controlButtonActive,
              ]}
              onPress={() =>
                setEnablePoseDataStreaming(!enablePoseDataStreaming)
              }
            >
              <Text style={styles.controlButtonText}>
                Data Streaming: {enablePoseDataStreaming ? 'ON' : 'OFF'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.controlButton,
                autoAdjustFPS && styles.controlButtonActive,
              ]}
              onPress={() => setAutoAdjustFPS(!autoAdjustFPS)}
            >
              <Text style={styles.controlButtonText}>
                Auto FPS: {autoAdjustFPS ? 'ON' : 'OFF'}
              </Text>
            </TouchableOpacity>

            <View style={styles.fpsButtons}>
              {[15, 30, 60].map((fpsValue) => (
                <TouchableOpacity
                  key={fpsValue}
                  style={[
                    styles.fpsButton,
                    targetFPS === fpsValue && styles.fpsButtonActive,
                  ]}
                  onPress={() => setTargetFPS(fpsValue)}
                >
                  <Text style={styles.fpsButtonText}>{fpsValue}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camera: {
    flex: 1,
  },
  performanceOverlay: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 10,
    padding: 15,
  },
  performanceText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 10,
  },
  toggleButton: {
    backgroundColor: '#007AFF',
    padding: 8,
    borderRadius: 6,
    alignItems: 'center',
  },
  toggleButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  controlsPanel: {
    marginTop: 10,
  },
  controlButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    padding: 8,
    borderRadius: 6,
    marginBottom: 8,
    alignItems: 'center',
  },
  controlButtonActive: {
    backgroundColor: '#4CAF50',
  },
  controlButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '500',
  },
  fpsButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 8,
  },
  fpsButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    padding: 8,
    borderRadius: 6,
    minWidth: 40,
    alignItems: 'center',
  },
  fpsButtonActive: {
    backgroundColor: '#007AFF',
  },
  fpsButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
});
```

## 📚 API Reference

### ReactNativeMediapipePoseView Props

#### Core Properties

| Prop                  | Type                   | Default   | Description                                        |
| --------------------- | ---------------------- | --------- | -------------------------------------------------- |
| `style`               | `StyleProp<ViewStyle>` | -         | Camera view styling and layout properties          |
| `cameraType`          | `'front' \| 'back'`    | `'front'` | Camera position selection (front-facing or back)   |
| `enablePoseDetection` | `boolean`              | `false`   | Enable/disable real-time pose detection processing |

#### Performance & Data Control

| Prop                      | Type      | Default | Description                                                   |
| ------------------------- | --------- | ------- | ------------------------------------------------------------- |
| `enablePoseDataStreaming` | `boolean` | `false` | **CRITICAL**: Enable pose data transmission to React Native   |
| `poseDataThrottleMs`      | `number`  | `100`   | Throttle pose data events to reduce bridge overhead (ms)      |
| `enableDetailedLogs`      | `boolean` | `false` | Enable comprehensive logging (disable for production)         |
| `fpsChangeThreshold`      | `number`  | `2.0`   | Minimum FPS change required to trigger onFrameProcessed event |
| `fpsReportThrottleMs`     | `number`  | `500`   | Throttle frequency for FPS reporting to reduce bridge calls   |

#### Frame Rate & Performance Optimization

| Prop            | Type      | Default | Description                                                |
| --------------- | --------- | ------- | ---------------------------------------------------------- |
| `targetFPS`     | `number`  | `30`    | Target frames per second for pose detection processing     |
| `autoAdjustFPS` | `boolean` | `true`  | Enable automatic FPS adjustment based on device capability |

### Events & Callbacks

#### Core Event Handlers

| Event              | Type                                                    | Description                                           |
| ------------------ | ------------------------------------------------------- | ----------------------------------------------------- |
| `onCameraReady`    | `(event: { nativeEvent: { ready: boolean } }) => void`  | Triggered when camera initializes and is ready to use |
| `onError`          | `(event: { nativeEvent: { error: string } }) => void`   | Camera or pose detection errors                       |
| `onPoseDetected`   | `(event: { nativeEvent: PoseDetectionResult }) => void` | **Requires enablePoseDataStreaming=true**             |
| `onFrameProcessed` | `(event: { nativeEvent: FrameProcessingInfo }) => void` | Frame processing statistics and FPS monitoring        |

#### Performance Monitoring Events

| Event                | Type                                                      | Description                                      |
| -------------------- | --------------------------------------------------------- | ------------------------------------------------ |
| `onDeviceCapability` | `(event: { nativeEvent: DeviceCapability }) => void`      | Device performance tier and recommended settings |
| `onGPUStatus`        | `(event: { nativeEvent: GPUStatusEvent }) => void`        | GPU acceleration status and delegate information |
| `onPoseServiceLog`   | `(event: { nativeEvent: PoseServiceLogEvent }) => void`   | **Requires enableDetailedLogs=true**             |
| `onPoseServiceError` | `(event: { nativeEvent: PoseServiceErrorEvent }) => void` | Pose service specific errors and recovery info   |

### Data Types & Interfaces

#### PoseDetectionResult

**Available only when `enablePoseDataStreaming={true}`**

```tsx
interface PoseDetectionResult {
  landmarks: PoseLandmark[]; // Array of 33 pose landmarks with coordinates
  processingTime: number; // Processing time in milliseconds
  timestamp: number; // Detection timestamp (Unix time)
  confidence: number; // Overall detection confidence (0.0 - 1.0)

  // Extended data (when enableDetailedLogs=true):
  deviceTier?: string; // 'high' | 'medium' | 'low'
  gpuAccelerated?: boolean; // Current GPU acceleration status
  processingUnit?: string; // 'GPU' | 'CPU' processing unit
  delegate?: string; // MediaPipe delegate type ('GPU' | 'CPU')
}
```

#### PoseLandmark

**33 Body Landmarks with 3D Coordinates**

```tsx
interface PoseLandmark {
  x: number; // Normalized x coordinate (0.0 - 1.0)
  y: number; // Normalized y coordinate (0.0 - 1.0)
  z: number; // Normalized z coordinate (depth, relative to hips)
  visibility: number; // Landmark visibility confidence (0.0 - 1.0)
}

// Landmark indices (0-32):
// 0: nose, 1-6: eyes, 7-8: ears, 9-10: mouth corners
// 11-12: shoulders, 13-14: elbows, 15-16: wrists
// 17-22: hand landmarks, 23-24: hips, 25-26: knees
// 27-28: ankles, 29-30: heels, 31-32: foot indices
```

#### FrameProcessingInfo

```tsx
interface FrameProcessingInfo {
  fps: number; // Current frames per second
  autoAdjusted?: boolean; // Whether FPS was automatically adjusted
  newTargetFPS?: number; // New target FPS after auto-adjustment
  reason?: string; // Reason for FPS adjustment
  processingTime?: number; // Frame processing time (ms)
  droppedFrames?: number; // Count of dropped frames
}
```

#### DeviceCapability

**Automatic Device Performance Detection**

```tsx
interface DeviceCapability {
  deviceTier: 'high' | 'medium' | 'low'; // Performance classification
  recommendedFPS: number; // Optimal FPS for this device
  processorCount: number; // Number of CPU cores
  physicalMemoryGB: number; // Available RAM in GB

  // Device classification examples:
  // high: iPhone 12 Pro+, iPad Pro M1+ → 60 FPS, GPU acceleration
  // medium: iPhone XS-12, iPad Air → 30 FPS, GPU acceleration
  // low: iPhone X-, older iPads → 15 FPS, CPU processing
}
```

#### GPUStatusEvent

```tsx
interface GPUStatusEvent {
  isUsingGPU: boolean; // Current GPU acceleration status
  delegate: string; // 'GPU' | 'CPU' delegate type
  processingUnit: string; // Detailed processing unit description
  deviceTier: string; // Device performance tier
  metalSupported?: boolean; // Metal framework availability (iOS)
}
```

#### PoseServiceLogEvent & PoseServiceErrorEvent

**Available only when `enableDetailedLogs={true}`**

```tsx
interface PoseServiceLogEvent {
  message: string; // Log message content
  level: string; // Log level ('info', 'warning', 'debug')
  timestamp: number; // Log timestamp
}

interface PoseServiceErrorEvent {
  error: string; // Error description
  processingTime: number; // Time when error occurred (ms)
  recoverable?: boolean; // Whether error is recoverable
  suggestion?: string; // Recovery suggestion
}
```

### Static Methods

#### ReactNativeMediapipePose Module Methods

```tsx
import ReactNativeMediapipePose from 'react-native-mediapipe-pose';

// Camera permission management
const granted: boolean = await ReactNativeMediapipePose.requestCameraPermissions();

// Camera switching (requires view reference)
await ReactNativeMediapipePose.switchCamera(viewTag: number);

// GPU status inquiry (requires view reference)
const gpuStatus = await ReactNativeMediapipePose.getGPUStatus(viewTag: number);
```

### Performance Configuration Guide

#### Production Optimization (Maximum Performance)

```tsx
<ReactNativeMediapipePoseView
  enablePoseDetection={true}
  // CRITICAL: Disable data streaming for max performance
  enablePoseDataStreaming={false} // Eliminates bridge overhead
  enableDetailedLogs={false} // Reduces logging overhead
  // Optimize bridge communication
  poseDataThrottleMs={200} // Higher throttling
  fpsReportThrottleMs={1000} // Reduce FPS reports
  fpsChangeThreshold={5.0} // Only significant changes
  // Auto-optimization
  autoAdjustFPS={true} // Device-based adjustment
  targetFPS={30} // Conservative target
  // Essential events only
  onFrameProcessed={handleFPS} // Monitor performance
  onDeviceCapability={handleDevice} // Device optimization
  onError={handleErrors} // Error handling
  // onPoseDetected - NOT NEEDED when streaming disabled
/>
```

#### Development & Debugging (Full Monitoring)

```tsx
<ReactNativeMediapipePoseView
  enablePoseDetection={true}
  // Enable all data for development
  enablePoseDataStreaming={true} // Access pose data
  enableDetailedLogs={true} // Comprehensive logging
  // Fast updates for development
  poseDataThrottleMs={50} // Fast pose data
  fpsReportThrottleMs={250} // Frequent FPS updates
  fpsChangeThreshold={1.0} // Sensitive monitoring
  // Performance monitoring
  targetFPS={60} // High target for testing
  autoAdjustFPS={true} // Test auto-adjustment
  // Full event monitoring
  onPoseDetected={handlePoseData} // Process pose landmarks
  onFrameProcessed={handleFrames} // Monitor performance
  onDeviceCapability={handleDevice} // Device analysis
  onGPUStatus={handleGPU} // GPU monitoring
  onPoseServiceLog={handleLogs} // Service logs
  onPoseServiceError={handleErrors} // Error analysis
/>
```

#### Hybrid Mode (Selective Data Streaming)

```tsx
const [needsPoseData, setNeedsPoseData] = useState(false);

<ReactNativeMediapipePoseView
  enablePoseDetection={true}
  // Dynamic data streaming
  enablePoseDataStreaming={needsPoseData} // Toggle as needed
  enableDetailedLogs={__DEV__} // Dev-only logging
  // Balanced performance
  poseDataThrottleMs={100} // Moderate throttling
  fpsReportThrottleMs={500} // Standard reporting
  autoAdjustFPS={true} // Auto-optimization
  // Conditional pose data handling
  onPoseDetected={needsPoseData ? handlePoseData : undefined}
  onFrameProcessed={handlePerformance}
  onDeviceCapability={handleCapability}
/>;
```

## ⚡ Performance Guidelines

### Production Optimization

For maximum performance in production environments:

```tsx
<ReactNativeMediapipePoseView
  enablePoseDataStreaming={false} // Critical: Disable for max performance
  enableDetailedLogs={false} // Critical: Disable for production
  poseDataThrottleMs={200} // Increase throttling
  fpsReportThrottleMs={1000} // Reduce FPS reporting frequency
  autoAdjustFPS={true} // Enable automatic optimization
  targetFPS={30} // Conservative target for stability
/>
```

### Development Monitoring

For development and debugging:

```tsx
<ReactNativeMediapipePoseView
  enablePoseDataStreaming={true} // Enable for data access
  enableDetailedLogs={true} // Enable for debugging
  poseDataThrottleMs={50} // Fast updates for testing
  onPoseDetected={handlePoseData}
  onGPUStatus={handleGPUStatus}
  onFrameProcessed={handlePerformance}
/>
```

### Device Performance Tiers

The module automatically detects device performance and adjusts accordingly:

- **High Tier**: iPhone 12 Pro and newer - GPU acceleration, 60 FPS target
- **Medium Tier**: iPhone XS to iPhone 12 - GPU acceleration, 30 FPS target
- **Low Tier**: iPhone X and older - CPU processing, 15 FPS target

## 🔧 Advanced Configuration

### Complete Performance Monitoring

```tsx
import React, { useState, useCallback } from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import {
  ReactNativeMediapipePoseView,
  DeviceCapability,
  FrameProcessingInfo,
  PoseDetectionResult,
} from 'react-native-mediapipe-pose';

export default function AdvancedPoseDetection() {
  const [performanceMetrics, setPerformanceMetrics] = useState({
    fps: 0,
    avgProcessingTime: 0,
    poseCount: 0,
    deviceTier: 'unknown',
    isUsingGPU: false,
  });

  const [logs, setLogs] = useState<string[]>([]);
  const [lastError, setLastError] = useState<string | null>(null);

  const addLog = useCallback((message: string) => {
    setLogs((prev) => [
      ...prev.slice(-19),
      `${new Date().toLocaleTimeString()}: ${message}`,
    ]);
  }, []);

  const handleFrameProcessed = useCallback(
    (event: { nativeEvent: FrameProcessingInfo }) => {
      const { fps, autoAdjusted, newTargetFPS, reason } = event.nativeEvent;

      setPerformanceMetrics((prev) => ({
        ...prev,
        fps: Math.round(fps),
      }));

      if (autoAdjusted && newTargetFPS && reason) {
        addLog(`Auto-adjusted FPS to ${newTargetFPS}: ${reason}`);
      }
    },
    [addLog]
  );

  const handlePoseDetected = useCallback(
    (event: { nativeEvent: PoseDetectionResult }) => {
      const { landmarks, processingTime, confidence } = event.nativeEvent;

      setPerformanceMetrics((prev) => ({
        ...prev,
        avgProcessingTime: (prev.avgProcessingTime + processingTime) / 2,
        poseCount: prev.poseCount + 1,
      }));

      addLog(
        `Detected ${landmarks.length} landmarks (${processingTime.toFixed(1)}ms, conf: ${confidence.toFixed(2)})`
      );
    },
    [addLog]
  );

  const handleDeviceCapability = useCallback(
    (event: { nativeEvent: DeviceCapability }) => {
      const { deviceTier, recommendedFPS, processorCount, physicalMemoryGB } =
        event.nativeEvent;

      setPerformanceMetrics((prev) => ({ ...prev, deviceTier }));
      addLog(
        `Device: ${deviceTier}, ${processorCount} cores, ${physicalMemoryGB.toFixed(1)}GB RAM, rec. FPS: ${recommendedFPS}`
      );
    },
    [addLog]
  );

  const handleGPUStatus = useCallback(
    (event: { nativeEvent: any }) => {
      const { isUsingGPU, delegate, processingUnit, deviceTier } =
        event.nativeEvent;

      setPerformanceMetrics((prev) => ({ ...prev, isUsingGPU }));
      addLog(
        `GPU: ${isUsingGPU ? 'Enabled' : 'Disabled'}, Delegate: ${delegate}, Unit: ${processingUnit}`
      );
    },
    [addLog]
  );

  const handlePoseServiceError = useCallback(
    (event: { nativeEvent: any }) => {
      const { error, processingTime } = event.nativeEvent;
      const errorMsg = `${error} (${processingTime}ms)`;

      setLastError(errorMsg);
      addLog(`ERROR: ${errorMsg}`);

      // Auto-clear error after 5 seconds
      setTimeout(() => setLastError(null), 5000);
    },
    [addLog]
  );

  return (
    <View style={styles.container}>
      <ReactNativeMediapipePoseView
        style={styles.camera}
        enablePoseDetection={true}
        enablePoseDataStreaming={true}
        enableDetailedLogs={true} // Enable for debugging
        poseDataThrottleMs={50} // Fast updates for development
        targetFPS={30}
        autoAdjustFPS={true}
        onFrameProcessed={handleFrameProcessed}
        onPoseDetected={handlePoseDetected}
        onDeviceCapability={handleDeviceCapability}
        onGPUStatus={handleGPUStatus}
        onPoseServiceError={handlePoseServiceError}
        onPoseServiceLog={(event) =>
          addLog(`Service: ${event.nativeEvent.message}`)
        }
      />

      {/* Performance Dashboard */}
      <View style={styles.dashboard}>
        <Text style={styles.dashboardTitle}>Performance Dashboard</Text>

        <View style={styles.metricsRow}>
          <Text style={styles.metric}>FPS: {performanceMetrics.fps}</Text>
          <Text style={styles.metric}>
            Avg Time: {performanceMetrics.avgProcessingTime.toFixed(1)}ms
          </Text>
          <Text style={styles.metric}>
            Poses: {performanceMetrics.poseCount}
          </Text>
        </View>

        <View style={styles.metricsRow}>
          <Text style={styles.metric}>
            Device: {performanceMetrics.deviceTier.toUpperCase()}
          </Text>
          <Text
            style={[
              styles.metric,
              { color: performanceMetrics.isUsingGPU ? '#4CAF50' : '#FF9800' },
            ]}
          >
            {performanceMetrics.isUsingGPU ? 'GPU' : 'CPU'}
          </Text>
        </View>

        {lastError && <Text style={styles.errorText}>❌ {lastError}</Text>}

        {/* Live Logs */}
        <ScrollView
          style={styles.logsContainer}
          showsVerticalScrollIndicator={false}
        >
          {logs.map((log, index) => (
            <Text key={index} style={styles.logText}>
              {log}
            </Text>
          ))}
        </ScrollView>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camera: {
    flex: 1,
  },
  dashboard: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    borderRadius: 10,
    padding: 15,
    maxHeight: 300,
  },
  dashboardTitle: {
    color: '#4CAF50',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  metric: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  errorText: {
    color: '#FF5252',
    fontSize: 12,
    marginVertical: 5,
  },
  logsContainer: {
    maxHeight: 120,
    marginTop: 10,
  },
  logText: {
    color: '#E0E0E0',
    fontSize: 10,
    fontFamily: 'monospace',
    marginBottom: 2,
  },
});
```

### Error Handling & Recovery

```tsx
const handleError = (event: { nativeEvent: { error: string } }) => {
  const { error } = event.nativeEvent;
  console.error('Pose detection error:', error);

  // Handle specific error types
  if (error.includes('Camera')) {
    Alert.alert(
      'Camera Error',
      'Please check camera permissions and try again.'
    );
  } else if (error.includes('GPU') || error.includes('Metal')) {
    console.log('GPU error detected, falling back to CPU processing');
    // GPU errors are automatically handled by the module
  } else if (error.includes('Model')) {
    Alert.alert(
      'Model Error',
      'Please ensure the pose detection model is properly installed.'
    );
  }

  // Implement automatic recovery
  setEnablePoseDetection(false);
  setTimeout(() => {
    console.log('Attempting to restart pose detection...');
    setEnablePoseDetection(true);
  }, 2000);
};

const handleCameraNotReady = () => {
  console.log('Camera not ready, checking simulator...');

  if (__DEV__ && Platform.OS === 'ios') {
    Alert.alert(
      'iOS Simulator',
      'Camera is not available in iOS Simulator. Please test on a physical device.',
      [{ text: 'OK' }]
    );
  }
};
```

## 🏗️ Architecture

### Native Layer

- **Swift Implementation** - High-performance native iOS implementation
- **MediaPipe Integration** - Direct integration with MediaPipe TasksVision
- **Metal Framework** - GPU acceleration through Metal framework
- **Optimized Bridge** - Minimal React Native bridge communication

### Performance Features

- **Automatic Hardware Detection** - Dynamic GPU/CPU delegate selection
- **Smart Data Transmission** - Optional pose data streaming with throttling
- **Memory Management** - Efficient memory usage with automatic cleanup
- **Background Processing** - Non-blocking pose detection pipeline

### Platform Status

- **iOS**: Fully implemented with MediaPipe BlazePose and GPU acceleration
- **Android**: Under active development (MediaPipe Android integration in progress)
- **Web**: Basic camera functionality (pose detection coming soon)

## 🛠️ Development

### Building from Source

```bash
git clone https://github.com/your-repo/react-native-mediapipe-pose.git
cd react-native-mediapipe-pose
npm install

# Run example app
cd example
npm install
npx expo run:ios
```

### Testing

```bash
npm run test
npm run lint
npm run build
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 🆘 Support

- � Issues: [GitHub Issues](https://github.com/your-repo/react-native-mediapipe-pose/issues)
- 📖 Documentation: [API Reference](#api-reference)
- � Discussions: [GitHub Discussions](https://github.com/your-repo/react-native-mediapipe-pose/discussions)

---

<div align="center">
Made with ❤️ for the React Native community
</div>
