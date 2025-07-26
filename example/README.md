# React Native MediaPipe Pose - Example App

This example demonstrates the implementation of React Native MediaPipe Pose detection with GPU acceleration and performance optimization.

## Features

- ✨ **Production-Ready**: Optimized for production deployment
- 🚀 **GPU Acceleration**: Automatic GPU/CPU detection with Metal framework
- 📊 **Performance Monitoring**: Real-time FPS tracking and device capability detection
- ⚡ **Optimization Controls**: Configurable pose data streaming and logging levels
- 🎯 **High Accuracy**: 0.5 confidence threshold for maximum precision
- 📱 **Device Adaptive**: Automatic FPS adjustment based on device capabilities

## Quick Start

```bash
cd example
npm install
npx expo run:ios
```

## Performance Optimization

### Essential Controls

The example includes advanced performance controls:

- **Pose Data Streaming**: Disable for maximum performance (default: OFF)
- **Detailed Logs**: Enable only for debugging (default: OFF)
- **Data Throttling**: Configure streaming frequency (default: 100ms)
- **FPS Auto-Adjustment**: Automatic performance tuning (default: ON)

### Device Tier Optimization

The app automatically detects device capabilities:

- **High-end devices**: 60 FPS with GPU acceleration
- **Mid-range devices**: 30 FPS with optimized settings
- **Lower-end devices**: 15-24 FPS with CPU fallback

## Usage Example

```typescript
import { ReactNativeMediapipePoseView } from 'react-native-mediapipe-pose';

<ReactNativeMediapipePoseView
  style={styles.camera}
  cameraType="front"
  enablePoseDetection={true}
  enablePoseDataStreaming={false}  // Optimize performance
  enableDetailedLogs={false}       // Production setting
  targetFPS={30}
  autoAdjustFPS={true}
  onPoseDetected={handlePoseDetected}
  onGPUStatus={handleGPUStatus}
/>
```

## Production Configuration

For production deployment, ensure these settings:

```typescript
const productionConfig = {
  enablePoseDataStreaming: false, // Maximum performance
  enableDetailedLogs: false, // Clean production logs
  poseDataThrottleMs: 100, // Optimal streaming frequency
  fpsChangeThreshold: 2.0, // Stable FPS reporting
  autoAdjustFPS: true, // Device optimization
};
```

## Architecture

- **Swift Module**: Optimized MediaPipe integration with Metal GPU detection
- **Performance Service**: Minimal overhead pose detection with 0.5 confidence
- **Bridge Communication**: Throttled data transmission for efficiency
- **Error Handling**: Comprehensive error reporting and recovery

## Testing

Test on physical iOS devices for optimal performance. Camera functionality is not available in iOS Simulator.

## Production Deployment

Before deploying to production:

1. Disable detailed logging (`enableDetailedLogs: false`)
2. Configure optimal throttling values
3. Test on target device range
4. Verify GPU acceleration status
5. Monitor performance metrics

For more details, see the main module [README](../README.md).
