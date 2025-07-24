import { registerWebModule, NativeModule } from 'expo';

import { ReactNativeMediapipePoseModuleEvents } from './ReactNativeMediapipePose.types';

class ReactNativeMediapipePoseModule extends NativeModule<ReactNativeMediapipePoseModuleEvents> {
  PI = Math.PI;

  async switchCamera(viewTag: number): Promise<void> {
    // Web implementation for camera switching can be handled in the component
    console.log('Switch camera called for view:', viewTag);
  }

  async requestCameraPermissions(): Promise<boolean> {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      stream.getTracks().forEach((track) => track.stop()); // Stop the stream immediately
      return true;
    } catch (error) {
      console.error('Camera permission denied:', error);
      return false;
    }
  }
}

export default registerWebModule(
  ReactNativeMediapipePoseModule,
  'ReactNativeMediapipePoseModule'
);
