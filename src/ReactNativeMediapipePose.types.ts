import type { StyleProp, ViewStyle } from 'react-native';

export type CameraType = 'front' | 'back';

export type PoseLandmark = {
  x: number;
  y: number;
  z: number;
  visibility: number;
};

export type PoseDetectionResult = {
  landmarks: PoseLandmark[];
  processingTime: number; // in milliseconds
  timestamp: number;
};

export type FrameProcessingInfo = {
  fps: number;
  frameCount: number;
  autoAdjusted?: boolean;
  newTargetFPS?: number;
  reason?: string;
};

export type DeviceCapability = {
  deviceTier: 'high' | 'medium' | 'low' | 'unknown';
  recommendedFPS: number;
  processorCount: number;
  physicalMemoryGB: number;
  systemVersion: string;
};

export type OnCameraReadyEventPayload = {
  ready: boolean;
};

export type OnErrorEventPayload = {
  error: string;
};

export type ReactNativeMediapipePoseModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
};

export type ChangeEventPayload = {
  value: string;
};

export type ReactNativeMediapipePoseViewProps = {
  style?: StyleProp<ViewStyle>;
  cameraType?: CameraType;
  enablePoseDetection?: boolean;
  targetFPS?: number;
  autoAdjustFPS?: boolean;
  onCameraReady?: (event: { nativeEvent: OnCameraReadyEventPayload }) => void;
  onError?: (event: { nativeEvent: OnErrorEventPayload }) => void;
  onFrameProcessed?: (event: { nativeEvent: FrameProcessingInfo }) => void;
  onPoseDetected?: (event: { nativeEvent: PoseDetectionResult }) => void;
  onDeviceCapability?: (event: { nativeEvent: DeviceCapability }) => void;
};
