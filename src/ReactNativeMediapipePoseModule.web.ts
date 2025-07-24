import { registerWebModule, NativeModule } from 'expo';

import { ReactNativeMediapipePoseModuleEvents } from './ReactNativeMediapipePose.types';

class ReactNativeMediapipePoseModule extends NativeModule<ReactNativeMediapipePoseModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ReactNativeMediapipePoseModule, 'ReactNativeMediapipePoseModule');
