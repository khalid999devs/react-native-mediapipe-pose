import { requireNativeView } from 'expo';
import * as React from 'react';

import { ReactNativeMediapipePoseViewProps } from './ReactNativeMediapipePose.types';

const NativeView: React.ComponentType<ReactNativeMediapipePoseViewProps> =
  requireNativeView('ReactNativeMediapipePose');

export default function ReactNativeMediapipePoseView(props: ReactNativeMediapipePoseViewProps) {
  return <NativeView {...props} />;
}
