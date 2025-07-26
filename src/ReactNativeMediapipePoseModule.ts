import { NativeModule, requireNativeModule } from 'expo';
import { ReactNativeMediapipePoseModuleEvents } from './ReactNativeMediapipePose.types';

/**
 * Native module interface for React Native MediaPipe Pose Detection
 * Provides camera control and GPU status functionality
 */
declare class ReactNativeMediapipePoseModule extends NativeModule<ReactNativeMediapipePoseModuleEvents> {
  /** Mathematical constant PI */
  PI: number;

  /**
   * Switch between front and back camera
   * @param viewTag - React Native view tag identifier
   */
  switchCamera(viewTag: number): Promise<void>;

  /**
   * Request camera permissions from the user
   * @returns Promise resolving to true if granted, false otherwise
   */
  requestCameraPermissions(): Promise<boolean>;

  /**
   * Get current GPU acceleration status and hardware information
   * @param viewTag - React Native view tag identifier
   * @returns GPU status object with acceleration info
   */
  getGPUStatus(viewTag: number): any;
}

/**
 * React Native MediaPipe Pose Detection Module
 * Pose detection with GPU acceleration and performance optimization
 */
export default requireNativeModule<ReactNativeMediapipePoseModule>(
  'ReactNativeMediapipePose'
);
