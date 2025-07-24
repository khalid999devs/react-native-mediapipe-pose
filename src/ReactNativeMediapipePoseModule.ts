import { NativeModule, requireNativeModule } from 'expo';

import { ReactNativeMediapipePoseModuleEvents } from './ReactNativeMediapipePose.types';

declare class ReactNativeMediapipePoseModule extends NativeModule<ReactNativeMediapipePoseModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ReactNativeMediapipePoseModule>('ReactNativeMediapipePose');
