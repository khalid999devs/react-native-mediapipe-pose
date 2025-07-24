import type { StyleProp, ViewStyle } from 'react-native';

export type CameraType = 'front' | 'back';

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
  onCameraReady?: (event: { nativeEvent: OnCameraReadyEventPayload }) => void;
  onError?: (event: { nativeEvent: OnErrorEventPayload }) => void;
};
