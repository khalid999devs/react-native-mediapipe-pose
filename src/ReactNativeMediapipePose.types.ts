import type { StyleProp, ViewStyle } from 'react-native';

/**
 * Camera position types supported by the pose detection module
 */
export type CameraType = 'front' | 'back';

/**
 * Individual pose landmark with 3D coordinates and visibility confidence
 */
export type PoseLandmark = {
  /** Normalized x coordinate (0-1) */
  x: number;
  /** Normalized y coordinate (0-1) */
  y: number;
  /** Normalized z coordinate (depth) */
  z: number;
  /** Visibility confidence score (0-1) */
  visibility: number;
};

/**
 * Complete pose detection result with performance metrics
 */
export type PoseDetectionResult = {
  /** Array of detected pose landmarks */
  landmarks: PoseLandmark[];
  /** Processing time in milliseconds */
  processingTime: number;
  /** Detection timestamp */
  timestamp: number;
  /** Device performance tier (only in detailed mode) */
  deviceTier?: string;
  /** Overall detection confidence */
  confidence?: number;
  /** Whether GPU acceleration is active (only in detailed mode) */
  gpuAccelerated?: boolean;
  /** Processing unit description (only in detailed mode) */
  processingUnit?: string;
  /** MediaPipe delegate type (only in detailed mode) */
  delegate?: string;
};

/**
 * Frame processing performance information
 */
export type FrameProcessingInfo = {
  /** Current frames per second */
  fps: number;
  /** Total frames processed */
  frameCount: number;
  /** Whether FPS was automatically adjusted */
  autoAdjusted?: boolean;
  /** New target FPS after adjustment */
  newTargetFPS?: number;
  /** Reason for adjustment */
  reason?: string;
};

/**
 * Device hardware capability assessment
 */
export type DeviceCapability = {
  /** Performance tier classification */
  deviceTier: 'high' | 'medium' | 'low' | 'unknown';
  /** Recommended FPS for optimal performance */
  recommendedFPS: number;
  /** Number of CPU cores */
  processorCount: number;
  /** Physical memory in GB */
  physicalMemoryGB: number;
  /** iOS system version */
  systemVersion: string;
};

/**
 * Camera ready state event
 */
export type OnCameraReadyEventPayload = {
  ready: boolean;
};

/**
 * Error event payload
 */
export type OnErrorEventPayload = {
  error: string;
};

/**
 * Service log event (only sent when detailed logging enabled)
 */
export type PoseServiceLogEvent = {
  message: string;
  level: 'info' | 'debug' | 'warning' | 'error';
  timestamp: number;
};

/**
 * Service error event
 */
export type PoseServiceErrorEvent = {
  error: string;
  processingTime: number;
};

/**
 * GPU acceleration status information
 */
export type GPUStatusEvent = {
  /** Whether GPU acceleration is currently active */
  isUsingGPU: boolean;
  /** MediaPipe delegate type */
  delegate: 'GPU' | 'CPU';
  /** Device performance tier */
  deviceTier: string;
  /** Whether maximum accuracy mode is enabled */
  maxAccuracy: boolean;
  /** Processing unit description */
  processingUnit: string;
};

export type ReactNativeMediapipePoseModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
};

export type ChangeEventPayload = {
  value: string;
};

/**
 * Main component props for pose detection camera view
 */
export type ReactNativeMediapipePoseViewProps = {
  /** View styling */
  style?: StyleProp<ViewStyle>;

  /** Camera position */
  cameraType?: CameraType;

  /** Enable/disable pose detection processing */
  enablePoseDetection?: boolean;

  /** Performance Optimization Props */
  /** Enable streaming pose data to React Native (default: false for max performance) */
  enablePoseDataStreaming?: boolean;
  /** Throttle pose data events in milliseconds (default: 100) */
  poseDataThrottleMs?: number;
  /** Enable detailed logging and metrics (default: false for max performance) */
  enableDetailedLogs?: boolean;
  /** Minimum FPS change threshold to report (default: 2.0) */
  fpsChangeThreshold?: number;
  /** Throttle FPS reports in milliseconds (default: 500) */
  fpsReportThrottleMs?: number;

  /** Frame Rate Props */
  /** Target frames per second */
  targetFPS?: number;
  /** Enable automatic FPS adjustment for performance */
  autoAdjustFPS?: boolean;

  /** Event Handlers */
  onCameraReady?: (event: { nativeEvent: OnCameraReadyEventPayload }) => void;
  onError?: (event: { nativeEvent: OnErrorEventPayload }) => void;
  onFrameProcessed?: (event: { nativeEvent: FrameProcessingInfo }) => void;
  onPoseDetected?: (event: { nativeEvent: PoseDetectionResult }) => void;
  onDeviceCapability?: (event: { nativeEvent: DeviceCapability }) => void;
  onPoseServiceLog?: (event: { nativeEvent: PoseServiceLogEvent }) => void;
  onPoseServiceError?: (event: { nativeEvent: PoseServiceErrorEvent }) => void;
  onGPUStatus?: (event: { nativeEvent: GPUStatusEvent }) => void;
};
