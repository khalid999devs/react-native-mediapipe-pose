import * as React from 'react';

import { ReactNativeMediapipePoseViewProps } from './ReactNativeMediapipePose.types';

export default function ReactNativeMediapipePoseView(
  props: ReactNativeMediapipePoseViewProps
) {
  const [mediaStream, setMediaStream] = React.useState<MediaStream | null>(
    null
  );
  const videoRef = React.useRef<HTMLVideoElement>(null);

  React.useEffect(() => {
    // Request camera access
    const constraints = {
      video: {
        facingMode: props.cameraType === 'front' ? 'user' : 'environment',
      },
    };

    navigator.mediaDevices
      .getUserMedia(constraints)
      .then((stream) => {
        setMediaStream(stream);
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }
        props.onCameraReady?.({ nativeEvent: { ready: true } });
      })
      .catch((error) => {
        console.error('Error accessing camera:', error);
        props.onError?.({ nativeEvent: { error: error.message } });
      });

    return () => {
      if (mediaStream) {
        mediaStream.getTracks().forEach((track) => track.stop());
      }
    };
  }, [props.cameraType]);

  return (
    <video
      ref={videoRef}
      autoPlay
      playsInline
      muted
      style={{
        width: '100%',
        height: '100%',
        objectFit: 'cover',
        ...(props.style as any),
      }}
    />
  );
}
