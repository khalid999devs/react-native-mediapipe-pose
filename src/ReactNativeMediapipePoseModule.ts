import { NativeModule, requireNativeModule } from 'expo';

import { ReactNativeMediapipePoseModuleEvents } from './ReactNativeMediapipePose.types';

declare class ReactNativeMediapipePoseModule extends NativeModule<ReactNativeMediapipePoseModuleEvents> {
  PI: number;
  switchCamera(viewTag: number): Promise<void>;
  requestCameraPermissions(): Promise<boolean>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ReactNativeMediapipePoseModule>(
  'ReactNativeMediapipePose'
);
