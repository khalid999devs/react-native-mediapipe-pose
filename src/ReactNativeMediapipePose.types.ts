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
  deviceTier?: string;
  confidence?: number;
  gpuAccelerated?: boolean; // New: indicates if GPU acceleration is being used
  processingUnit?: string; // New: describes the processing unit (Neural Engine/GPU vs CPU)
  delegate?: string; // New: MediaPipe delegate type (GPU or CPU)
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

export type PoseServiceLogEvent = {
  message: string;
  level: 'info' | 'debug' | 'warning' | 'error';
  timestamp: number;
};

export type PoseServiceErrorEvent = {
  error: string;
  processingTime: number;
};

export type GPUStatusEvent = {
  isUsingGPU: boolean;
  delegate: 'GPU' | 'CPU';
  deviceTier: string;
  maxAccuracy: boolean;
  processingUnit: string;
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
  enablePoseDataStreaming?: boolean; // New: controls whether to send pose data events (default: false for performance)
  poseDataThrottleMs?: number; // New: throttle pose data events (default: 100ms)
  enableDetailedLogs?: boolean; // New: controls detailed logging (default: false for performance)
  fpsChangeThreshold?: number; // New: minimum FPS change to report (default: 2.0)
  fpsReportThrottleMs?: number; // New: throttle FPS reports (default: 500ms)
  targetFPS?: number;
  autoAdjustFPS?: boolean;
  onCameraReady?: (event: { nativeEvent: OnCameraReadyEventPayload }) => void;
  onError?: (event: { nativeEvent: OnErrorEventPayload }) => void;
  onFrameProcessed?: (event: { nativeEvent: FrameProcessingInfo }) => void;
  onPoseDetected?: (event: { nativeEvent: PoseDetectionResult }) => void;
  onDeviceCapability?: (event: { nativeEvent: DeviceCapability }) => void;
  onPoseServiceLog?: (event: { nativeEvent: PoseServiceLogEvent }) => void;
  onPoseServiceError?: (event: { nativeEvent: PoseServiceErrorEvent }) => void;
  onGPUStatus?: (event: { nativeEvent: GPUStatusEvent }) => void; // New GPU status event
};
