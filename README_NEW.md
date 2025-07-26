# React Native MediaPipe Pose

<div align="center">

[![npm version](https://badge.fury.io/js/react-native-mediapipe-pose.svg)](https://badge.fury.io/js/react-native-mediapipe-pose)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://reactnative.dev/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**Enterprise-grade React Native module for real-time pose detection using Google's MediaPipe BlazePose**

_Production-ready pose detection with GPU acceleration, automatic hardware optimization, and enterprise-level performance monitoring_

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

### 🔧 **Enterprise Configuration**

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

## 📦 Installation

### Prerequisites

- React Native >= 0.72
- Expo SDK >= 53
- iOS >= 12.0
- Xcode >= 14

### Install Package

```bash
npm install react-native-mediapipe-pose
# or
yarn add react-native-mediapipe-pose
```

### iOS Setup

Add the MediaPipe pose detection model to your iOS project:

1. Download the MediaPipe pose model file (`pose_landmarker_full.task`)
2. Add it to your iOS project bundle
3. Ensure camera permissions in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for pose detection</string>
```

## 🚀 Quick Start

### Basic Implementation

```tsx
import React, { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import {
  ReactNativeMediapipePoseView,
  PoseDetectionResult,
  CameraType,
} from 'react-native-mediapipe-pose';

export default function App() {
  const [cameraType, setCameraType] = useState<CameraType>('front');

  const handlePoseDetected = (event: { nativeEvent: PoseDetectionResult }) => {
    const { landmarks, processingTime, confidence } = event.nativeEvent;
    console.log(
      `Detected ${landmarks.length} landmarks in ${processingTime}ms`
    );
  };

  return (
    <View style={styles.container}>
      <ReactNativeMediapipePoseView
        style={styles.camera}
        cameraType={cameraType}
        enablePoseDetection={true}
        enablePoseDataStreaming={true} // Enable to receive pose data
        onPoseDetected={handlePoseDetected}
      />
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
});
```

### Performance Optimized Setup

```tsx
import React, { useState } from 'react';
import { ReactNativeMediapipePoseView } from 'react-native-mediapipe-pose';

export default function OptimizedPoseDetection() {
  return (
    <ReactNativeMediapipePoseView
      style={{ flex: 1 }}
      enablePoseDetection={true}
      // Performance optimizations (recommended for production)
      enablePoseDataStreaming={false} // Disable data streaming for max performance
      enableDetailedLogs={false} // Disable detailed logging for production
      poseDataThrottleMs={100} // Throttle data updates to 100ms
      fpsChangeThreshold={2.0} // Only report significant FPS changes
      fpsReportThrottleMs={500} // Throttle FPS reports to 500ms
      // Auto performance adjustment
      autoAdjustFPS={true} // Enable automatic FPS optimization
      targetFPS={30} // Target 30 FPS for stability
      onPoseDetected={(event) => {
        // Handle pose detection only when streaming is enabled
        console.log('Pose detected:', event.nativeEvent);
      }}
    />
  );
}
```

## 📚 API Reference

### Props

#### Core Properties

| Prop                  | Type                   | Default   | Description                   |
| --------------------- | ---------------------- | --------- | ----------------------------- |
| `style`               | `StyleProp<ViewStyle>` | -         | Camera view styling           |
| `cameraType`          | `'front' \| 'back'`    | `'front'` | Camera position               |
| `enablePoseDetection` | `boolean`              | `false`   | Enable/disable pose detection |

#### Performance Optimization

| Prop                      | Type      | Default | Description                                      |
| ------------------------- | --------- | ------- | ------------------------------------------------ |
| `enablePoseDataStreaming` | `boolean` | `false` | Enable pose data transmission to React Native    |
| `poseDataThrottleMs`      | `number`  | `100`   | Throttle pose data events (ms)                   |
| `enableDetailedLogs`      | `boolean` | `false` | Enable detailed logging (disable for production) |
| `fpsChangeThreshold`      | `number`  | `2.0`   | Minimum FPS change to report                     |
| `fpsReportThrottleMs`     | `number`  | `500`   | Throttle FPS reports (ms)                        |

#### Frame Rate Control

| Prop            | Type      | Default | Description                     |
| --------------- | --------- | ------- | ------------------------------- |
| `targetFPS`     | `number`  | `30`    | Target frames per second        |
| `autoAdjustFPS` | `boolean` | `true`  | Enable automatic FPS adjustment |

### Events

#### onPoseDetected

```tsx
onPoseDetected?: (event: { nativeEvent: PoseDetectionResult }) => void;
```

**PoseDetectionResult:**

```tsx
{
  landmarks: PoseLandmark[];      // Array of detected pose landmarks
  processingTime: number;         // Processing time in milliseconds
  timestamp: number;              // Detection timestamp
  confidence: number;             // Overall detection confidence (0-1)
  // Available only when enableDetailedLogs is true:
  deviceTier?: string;            // Device performance tier
  gpuAccelerated?: boolean;       // GPU acceleration status
  processingUnit?: string;        // Processing unit description
  delegate?: string;              // MediaPipe delegate type
}
```

**PoseLandmark:**

```tsx
{
  x: number; // Normalized x coordinate (0-1)
  y: number; // Normalized y coordinate (0-1)
  z: number; // Normalized z coordinate (depth)
  visibility: number; // Visibility confidence (0-1)
}
```

#### Other Events

```tsx
onCameraReady?: (event: { nativeEvent: { ready: boolean } }) => void;
onError?: (event: { nativeEvent: { error: string } }) => void;
onFrameProcessed?: (event: { nativeEvent: FrameProcessingInfo }) => void;
onDeviceCapability?: (event: { nativeEvent: DeviceCapability }) => void;
onGPUStatus?: (event: { nativeEvent: GPUStatusEvent }) => void;
```

### Methods

```tsx
import ReactNativeMediapipePose from 'react-native-mediapipe-pose';

// Switch camera
await ReactNativeMediapipePose.switchCamera(viewTag);

// Request camera permissions
const granted = await ReactNativeMediapipePose.requestCameraPermissions();

// Get GPU status
const gpuStatus = ReactNativeMediapipePose.getGPUStatus(viewTag);
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

### Custom Performance Monitoring

```tsx
const [performanceMetrics, setPerformanceMetrics] = useState({});

const handleFrameProcessed = (event) => {
  const { fps, processingTime, autoAdjusted } = event.nativeEvent;
  setPerformanceMetrics({ fps, processingTime, autoAdjusted });
};

const handleGPUStatus = (event) => {
  const { isUsingGPU, delegate, processingUnit } = event.nativeEvent;
  console.log(
    `GPU: ${isUsingGPU}, Delegate: ${delegate}, Unit: ${processingUnit}`
  );
};
```

### Error Handling

```tsx
const handleError = (event) => {
  const { error } = event.nativeEvent;
  console.error('Pose detection error:', error);

  // Implement fallback behavior
  setEnablePoseDetection(false);
  setTimeout(() => setEnablePoseDetection(true), 1000);
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

- 📧 Email: support@yourcompany.com
- 💬 Discord: [Join our community](https://discord.gg/yourserver)
- 📖 Documentation: [Full API docs](https://docs.yoursite.com)
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/react-native-mediapipe-pose/issues)

---

<div align="center">
Made with ❤️ for the React Native community
</div>
