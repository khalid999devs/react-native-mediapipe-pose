import React, { useState, useEffect } from 'react';
import {
  View,
  Button,
  Text,
  StyleSheet,
  Alert,
  SafeAreaView,
} from 'react-native';
import ReactNativeMediapipePose, {
  ReactNativeMediapipePoseView,
  CameraType,
} from 'react-native-mediapipe-pose';

export default function CameraExample() {
  const [cameraType, setCameraType] = useState<CameraType>('back');
  const [permissionStatus, setPermissionStatus] = useState<string>('unknown');
  const [cameraReady, setCameraReady] = useState<boolean>(false);
  const [lastError, setLastError] = useState<string | null>(null);

  useEffect(() => {
    // Request permissions on component mount
    requestPermissions();
  }, []);

  const requestPermissions = async () => {
    try {
      setPermissionStatus('requesting...');
      const granted = await ReactNativeMediapipePose.requestCameraPermissions();
      setPermissionStatus(granted ? 'granted' : 'denied');

      if (!granted) {
        Alert.alert(
          'Camera Permission Required',
          'This app requires camera access to detect poses. Please grant camera permission in Settings.'
        );
      }
    } catch (error) {
      console.error('Error requesting camera permissions:', error);
      setPermissionStatus('error');
      Alert.alert('Error', 'Failed to request camera permissions');
    }
  };

  const switchCamera = () => {
    setCameraType((current) => {
      const newType = current === 'back' ? 'front' : 'back';
      console.log(`Switching camera from ${current} to ${newType}`);
      return newType;
    });
  };

  const handleCameraReady = ({
    nativeEvent: { ready },
  }: {
    nativeEvent: { ready: boolean };
  }) => {
    console.log('Camera ready:', ready);
    setCameraReady(ready);
    if (ready) {
      setLastError(null); // Clear any previous errors
    }
  };

  const handleCameraError = ({
    nativeEvent: { error },
  }: {
    nativeEvent: { error: string };
  }) => {
    console.error('Camera error:', error);
    setLastError(error);

    // Check if it's a simulator-related error
    if (error.includes('Simulator') || error.includes('simulator')) {
      Alert.alert(
        'iOS Simulator Limitation',
        'Camera functionality is not available in iOS Simulator. Please test on a physical iOS device to use camera features.',
        [{ text: 'OK' }]
      );
    } else {
      Alert.alert('Camera Error', error);
    }

    setCameraReady(false);
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>MediaPipe Pose Camera</Text>
        <Text style={styles.subtitle}>
          Real-time pose detection coming soon!
        </Text>
      </View>

      <View style={styles.statusContainer}>
        <Text style={styles.statusText}>
          Permission:{' '}
          <Text style={getStatusStyle(permissionStatus)}>
            {permissionStatus}
          </Text>
        </Text>
        <Text style={styles.statusText}>
          Camera:{' '}
          <Text style={getStatusStyle(cameraReady ? 'ready' : 'not ready')}>
            {cameraReady ? 'Ready' : 'Not Ready'}
          </Text>
        </Text>
        <Text style={styles.statusText}>
          Current Camera:{' '}
          <Text style={styles.highlight}>{cameraType.toUpperCase()}</Text>
        </Text>
      </View>

      <View style={styles.cameraContainer}>
        <ReactNativeMediapipePoseView
          style={styles.camera}
          cameraType={cameraType}
          onCameraReady={handleCameraReady}
          onError={handleCameraError}
        />

        {!cameraReady && (
          <View style={styles.overlay}>
            <Text style={styles.overlayText}>
              {lastError
                ? lastError.includes('simulator')
                  ? '📱 Camera not available in iOS Simulator\n\nPlease test on a physical device'
                  : `❌ ${lastError}`
                : permissionStatus === 'granted'
                  ? '📷 Loading camera...'
                  : '🔒 Camera permission required'}
            </Text>
          </View>
        )}
      </View>

      <View style={styles.controls}>
        <Button
          title={`Switch to ${cameraType === 'back' ? 'Front' : 'Back'} Camera`}
          onPress={switchCamera}
          disabled={!cameraReady}
        />

        <View style={styles.spacer} />

        <Button
          title='Request Permissions'
          onPress={requestPermissions}
          color='#007AFF'
        />
      </View>

      <View style={styles.info}>
        <Text style={styles.infoText}>
          🎯 This camera view will soon support real-time pose detection with
          MediaPipe!
        </Text>
        <Text style={styles.infoText}>
          📱 Try switching between front and back cameras
        </Text>
      </View>
    </SafeAreaView>
  );
}

const getStatusStyle = (status: string) => {
  if (status === 'granted' || status === 'ready') {
    return styles.statusGood;
  } else if (
    status === 'denied' ||
    status === 'error' ||
    status === 'not ready'
  ) {
    return styles.statusBad;
  }
  return styles.statusPending;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  statusContainer: {
    backgroundColor: 'white',
    margin: 20,
    padding: 15,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusText: {
    fontSize: 16,
    marginBottom: 5,
    color: '#333',
  },
  statusGood: {
    color: '#4CAF50',
    fontWeight: 'bold',
  },
  statusBad: {
    color: '#F44336',
    fontWeight: 'bold',
  },
  statusPending: {
    color: '#FF9800',
    fontWeight: 'bold',
  },
  highlight: {
    color: '#007AFF',
    fontWeight: 'bold',
  },
  cameraContainer: {
    flex: 1,
    margin: 20,
    borderRadius: 15,
    overflow: 'hidden',
    backgroundColor: '#000',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 5,
  },
  camera: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  overlayText: {
    color: 'white',
    fontSize: 18,
    textAlign: 'center',
    paddingHorizontal: 20,
  },
  controls: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  spacer: {
    width: 20,
  },
  info: {
    backgroundColor: '#E3F2FD',
    margin: 20,
    padding: 15,
    borderRadius: 10,
    borderLeftWidth: 4,
    borderLeftColor: '#2196F3',
  },
  infoText: {
    fontSize: 14,
    color: '#1976D2',
    marginBottom: 5,
    lineHeight: 20,
  },
});
