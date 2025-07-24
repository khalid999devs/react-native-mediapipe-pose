# React Native MediaPipe Pose

A React Native module for real-time pose detection using MediaPipe. This module provides a customizable camera view with front/back camera switching and will support real-time pose keypoint detection.

## Features

- 📱 **Camera View**: Customizable camera component with full style support
- 🔄 **Camera Switching**: Easy front/back camera switching
- 🎨 **Fully Customizable**: Style the camera view just like any React Native component
- 🍃 **iOS Support**: Optimized for iOS devices (Android support coming soon)
- ⚡ **Real-time**: Built for real-time pose detection (pose detection coming in next updates)

## Installation

```bash
npm install react-native-mediapipe-pose
```

## Usage

### Basic Camera View

```tsx
import React, { useState } from 'react';
import { View, Button, Alert } from 'react-native';
import {
  ReactNativeMediapipePoseView,
  CameraType,
} from 'react-native-mediapipe-pose';

export default function App() {
  const [cameraType, setCameraType] = useState<CameraType>('back');

  const switchCamera = () => {
    setCameraType((current) => (current === 'back' ? 'front' : 'back'));
  };

  return (
    <View style={{ flex: 1 }}>
      <ReactNativeMediapipePoseView
        style={{
          flex: 1,
          borderRadius: 10,
          margin: 20,
        }}
        cameraType={cameraType}
        onCameraReady={({ nativeEvent: { ready } }) => {
          console.log('Camera ready:', ready);
        }}
        onError={({ nativeEvent: { error } }) => {
          Alert.alert('Camera Error', error);
        }}
      />

      <Button
        title={`Switch to ${cameraType === 'back' ? 'Front' : 'Back'} Camera`}
        onPress={switchCamera}
      />
    </View>
  );
}
```

### Request Camera Permissions

```tsx
import ReactNativeMediapipePose from 'react-native-mediapipe-pose';

const requestPermissions = async () => {
  const granted = await ReactNativeMediapipePose.requestCameraPermissions();
  if (!granted) {
    Alert.alert('Permission Denied', 'Camera permission is required');
  }
};
```

## API Reference

### ReactNativeMediapipePoseView Props

| Prop            | Type                | Default     | Description                      |
| --------------- | ------------------- | ----------- | -------------------------------- |
| `style`         | `ViewStyle`         | `undefined` | Style object for the camera view |
| `cameraType`    | `'front' \| 'back'` | `'back'`    | Which camera to use              |
| `onCameraReady` | `function`          | `undefined` | Callback when camera is ready    |
| `onError`       | `function`          | `undefined` | Callback when an error occurs    |

### Module Methods

#### `requestCameraPermissions()`

Requests camera permissions from the user.

**Returns:** `Promise<boolean>` - `true` if permission granted, `false` otherwise

```tsx
const hasPermission = await ReactNativeMediapipePose.requestCameraPermissions();
```

#### `switchCamera(viewTag: number)`

Programmatically switches the camera for a specific view.

**Parameters:**

- `viewTag`: The native view tag (usually handled internally)

## Styling

The camera view can be styled just like any React Native View:

```tsx
<ReactNativeMediapipePoseView
  style={{
    width: 300,
    height: 400,
    borderRadius: 20,
    borderWidth: 3,
    borderColor: '#007AFF',
    margin: 10,
  }}
  cameraType='front'
/>
```

## Roadmap

- ✅ Basic camera view with styling support
- ✅ Front/back camera switching
- ✅ Permission handling
- 🔲 Real-time pose detection
- 🔲 Pose keypoint extraction
- 🔲 Custom pose detection models
- 🔲 Android support
- 🔲 Recording capabilities

## Requirements

- iOS 15.1+
- React Native 0.79+
- Expo SDK 53+

## License

MIT

## Contributing

We welcome contributions! Please see our contributing guidelines for more details.

## Support

If you encounter any issues or have questions, please file an issue on our GitHub repository.

# API documentation

- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/react-native-mediapipe-pose/)
- [Documentation for the main branch](https://docs.expo.dev/versions/unversioned/sdk/react-native-mediapipe-pose/)

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install react-native-mediapipe-pose
```

### Configure for Android

### Configure for iOS

Run `npx pod-install` after installing the npm package.

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide](https://github.com/expo/expo#contributing).
# react-native-mediapipe-pose
