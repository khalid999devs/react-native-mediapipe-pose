import * as React from 'react';

import { ReactNativeMediapipePoseViewProps } from './ReactNativeMediapipePose.types';

export default function ReactNativeMediapipePoseView(props: ReactNativeMediapipePoseViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
