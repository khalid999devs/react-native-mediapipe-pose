import React, { useState, useEffect } from 'react';
import {
  View,
  Button,
  Text,
  StyleSheet,
  Alert,
  SafeAreaView,
  TouchableOpacity,
  StatusBar,
  Dimensions,
} from 'react-native';
import ReactNativeMediapipePose, {
  ReactNativeMediapipePoseView,
  CameraType,
  PoseDetectionResult,
  FrameProcessingInfo,
  DeviceCapability,
} from 'react-native-mediapipe-pose';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

export default function CameraExample() {
  const [cameraType, setCameraType] = useState<CameraType>('back');
  const [permissionStatus, setPermissionStatus] = useState<string>('unknown');
  const [cameraReady, setCameraReady] = useState<boolean>(false);
  const [lastError, setLastError] = useState<string | null>(null);
  const [isPoseDetectionEnabled, setIsPoseDetectionEnabled] =
    useState<boolean>(false);
  const [fps, setFps] = useState<number>(0);
  const [poseCount, setPoseCount] = useState<number>(0);
  const [processingTime, setProcessingTime] = useState<number>(0);
  const [deviceCapability, setDeviceCapability] =
    useState<DeviceCapability | null>(null);
  const [targetFPS, setTargetFPS] = useState<number>(30);
  const [showFPSControls, setShowFPSControls] = useState<boolean>(false);
  const [autoAdjustFPS, setAutoAdjustFPS] = useState<boolean>(true);
  const [lastAutoAdjustment, setLastAutoAdjustment] = useState<string | null>(
    null
  );

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

  const handleFrameProcessed = ({
    nativeEvent: { fps: currentFps, autoAdjusted, newTargetFPS, reason },
  }: {
    nativeEvent: FrameProcessingInfo;
  }) => {
    setFps(Math.round(currentFps));

    // Handle auto-adjustment notifications
    if (autoAdjusted && newTargetFPS && reason) {
      setTargetFPS(newTargetFPS);
      setLastAutoAdjustment(`Auto-adjusted to ${newTargetFPS} FPS: ${reason}`);

      // Clear notification after 3 seconds
      setTimeout(() => setLastAutoAdjustment(null), 3000);
    }
  };

  const handlePoseDetected = ({
    nativeEvent: { landmarks, processingTime: procTime },
  }: {
    nativeEvent: PoseDetectionResult;
  }) => {
    setPoseCount((prev) => prev + 1);
    setProcessingTime(Math.round(procTime * 100) / 100); // Round to 2 decimal places

    // Log pose data (you can use this for debugging)
    console.log(
      `Pose detected with ${landmarks.length} landmarks, processing time: ${procTime}ms`
    );
  };

  const togglePoseDetection = () => {
    setIsPoseDetectionEnabled(!isPoseDetectionEnabled);
    if (!isPoseDetectionEnabled) {
      setPoseCount(0); // Reset counter when enabling
    }
  };

  const handleDeviceCapability = ({
    nativeEvent: capability,
  }: {
    nativeEvent: DeviceCapability;
  }) => {
    console.log('Device capability detected:', capability);
    setDeviceCapability(capability);
    setTargetFPS(capability.recommendedFPS); // Set recommended FPS automatically
  };

  const adjustFPS = (newFPS: number) => {
    const clampedFPS = Math.max(5, Math.min(60, newFPS));
    setTargetFPS(clampedFPS);
  };

  const toggleFPSControls = () => {
    setShowFPSControls(!showFPSControls);
  };

  return (
    <View style={styles.container}>
      <StatusBar
        barStyle='light-content'
        backgroundColor='transparent'
        translucent
      />

      {/* Fullscreen Camera */}
      <ReactNativeMediapipePoseView
        style={styles.camera}
        cameraType={cameraType}
        enablePoseDetection={isPoseDetectionEnabled}
        targetFPS={targetFPS}
        autoAdjustFPS={autoAdjustFPS}
        onCameraReady={handleCameraReady}
        onError={handleCameraError}
        onFrameProcessed={handleFrameProcessed}
        onPoseDetected={handlePoseDetected}
        onDeviceCapability={handleDeviceCapability}
      />

      {/* Camera Not Ready Overlay */}
      {!cameraReady && (
        <View style={styles.loadingOverlay}>
          <View style={styles.loadingContent}>
            <Text style={styles.loadingText}>
              {lastError
                ? lastError.includes('simulator')
                  ? '📱 Camera not available in iOS Simulator\n\nPlease test on a physical device'
                  : `❌ ${lastError}`
                : permissionStatus === 'granted'
                  ? '📷 Loading camera...'
                  : '🔒 Camera permission required'}
            </Text>
            {permissionStatus !== 'granted' && (
              <TouchableOpacity
                style={styles.permissionButton}
                onPress={requestPermissions}
              >
                <Text style={styles.permissionButtonText}>
                  Grant Permission
                </Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      )}

      {/* Top Stats Panel */}
      {cameraReady && (
        <View style={styles.topPanel}>
          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <Text style={styles.statLabel}>FPS</Text>
              <Text style={styles.statValue}>{fps}</Text>
            </View>

            <View style={styles.statItem}>
              <Text style={styles.statLabel}>Target</Text>
              <Text style={styles.statValue}>{targetFPS}</Text>
            </View>

            {deviceCapability && (
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Device</Text>
                <Text
                  style={[
                    styles.statValue,
                    {
                      color:
                        deviceCapability.deviceTier === 'high'
                          ? '#4CAF50'
                          : deviceCapability.deviceTier === 'medium'
                            ? '#FF9800'
                            : '#F44336',
                    },
                  ]}
                >
                  {deviceCapability.deviceTier.toUpperCase()}
                </Text>
              </View>
            )}

            {isPoseDetectionEnabled && (
              <>
                <View style={styles.statItem}>
                  <Text style={styles.statLabel}>Poses</Text>
                  <Text style={styles.statValue}>{poseCount}</Text>
                </View>
                <View style={styles.statItem}>
                  <Text style={styles.statLabel}>Time</Text>
                  <Text style={styles.statValue}>{processingTime}ms</Text>
                </View>
              </>
            )}
          </View>

          {/* FPS Controls */}
          {showFPSControls && (
            <View style={styles.fpsControls}>
              <Text style={styles.fpsControlsTitle}>FPS Control</Text>

              {/* Auto-Adjust Toggle */}
              <View style={styles.autoAdjustContainer}>
                <Text style={styles.autoAdjustLabel}>Auto-Adjust FPS:</Text>
                <TouchableOpacity
                  style={[
                    styles.toggleButton,
                    autoAdjustFPS && styles.toggleButtonActive,
                  ]}
                  onPress={() => setAutoAdjustFPS(!autoAdjustFPS)}
                >
                  <Text style={styles.toggleButtonText}>
                    {autoAdjustFPS ? 'ON' : 'OFF'}
                  </Text>
                </TouchableOpacity>
              </View>

              <View style={styles.fpsButtons}>
                {[15, 30, 60].map((fpsValue) => (
                  <TouchableOpacity
                    key={fpsValue}
                    style={[
                      styles.fpsButton,
                      targetFPS === fpsValue && styles.fpsButtonActive,
                    ]}
                    onPress={() => adjustFPS(fpsValue)}
                  >
                    <Text style={styles.fpsButtonText}>{fpsValue}</Text>
                  </TouchableOpacity>
                ))}
              </View>
              {deviceCapability && (
                <Text style={styles.deviceInfo}>
                  📱 {deviceCapability.processorCount} cores,{' '}
                  {deviceCapability.physicalMemoryGB.toFixed(1)}GB RAM
                </Text>
              )}
            </View>
          )}

          {/* Auto-Adjustment Notification */}
          {lastAutoAdjustment && (
            <View style={styles.autoAdjustNotification}>
              <Text style={styles.autoAdjustText}>🤖 {lastAutoAdjustment}</Text>
            </View>
          )}
        </View>
      )}

      {/* Bottom Controls */}
      {cameraReady && (
        <View style={styles.bottomPanel}>
          <TouchableOpacity style={styles.controlButton} onPress={switchCamera}>
            <Text style={styles.controlButtonText}>
              {cameraType === 'back' ? '🤳' : '📷'}
            </Text>
            <Text style={styles.controlButtonLabel}>
              {cameraType === 'back' ? 'Front' : 'Back'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.poseButton,
              isPoseDetectionEnabled && styles.poseButtonActive,
            ]}
            onPress={togglePoseDetection}
          >
            <Text style={styles.poseButtonText}>
              {isPoseDetectionEnabled ? '🎯' : '⏸️'}
            </Text>
            <Text style={styles.poseButtonLabel}>
              {isPoseDetectionEnabled ? 'Stop Pose' : 'Start Pose'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.controlButton}
            onPress={toggleFPSControls}
          >
            <Text style={styles.controlButtonText}>⚙️</Text>
            <Text style={styles.controlButtonLabel}>FPS</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Status Indicator */}
      {cameraReady && (
        <View style={styles.statusIndicator}>
          <View
            style={[
              styles.statusDot,
              { backgroundColor: cameraReady ? '#4CAF50' : '#F44336' },
            ]}
          />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  camera: {
    flex: 1,
    width: screenWidth,
    height: screenHeight,
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  loadingContent: {
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  loadingText: {
    color: 'white',
    fontSize: 18,
    textAlign: 'center',
    marginBottom: 20,
    lineHeight: 24,
  },
  permissionButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 25,
  },
  permissionButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  topPanel: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    zIndex: 100,
  },
  statsContainer: {
    flexDirection: 'row',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 20,
    paddingHorizontal: 20,
    paddingVertical: 10,
  },
  statItem: {
    alignItems: 'center',
    marginHorizontal: 8,
  },
  statLabel: {
    color: 'rgba(255, 255, 255, 0.8)',
    fontSize: 10,
    fontWeight: '500',
  },
  statValue: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
    marginTop: 1,
  },
  bottomPanel: {
    position: 'absolute',
    bottom: 40,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 40,
    zIndex: 100,
  },
  controlButton: {
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 50,
    width: 70,
    height: 70,
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  controlButtonText: {
    fontSize: 24,
    marginBottom: 2,
  },
  controlButtonLabel: {
    color: 'white',
    fontSize: 10,
    fontWeight: '600',
    textAlign: 'center',
  },
  poseButton: {
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 50,
    width: 80,
    height: 80,
    justifyContent: 'center',
    borderWidth: 3,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  poseButtonActive: {
    backgroundColor: 'rgba(76, 175, 80, 0.8)',
    borderColor: '#4CAF50',
  },
  poseButtonText: {
    fontSize: 28,
    marginBottom: 2,
  },
  poseButtonLabel: {
    color: 'white',
    fontSize: 10,
    fontWeight: '600',
    textAlign: 'center',
  },
  statusIndicator: {
    position: 'absolute',
    top: 50,
    right: 20,
    zIndex: 100,
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: 'white',
  },
  fpsControls: {
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    borderRadius: 15,
    padding: 15,
    marginTop: 10,
  },
  fpsControlsTitle: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 10,
  },
  fpsButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 10,
  },
  fpsButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 20,
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  fpsButtonActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  fpsButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  deviceInfo: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: 12,
    textAlign: 'center',
  },
  autoAdjustContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 15,
  },
  autoAdjustLabel: {
    color: 'white',
    fontSize: 14,
    fontWeight: '500',
  },
  toggleButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 15,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  toggleButtonActive: {
    backgroundColor: '#4CAF50',
    borderColor: '#4CAF50',
  },
  toggleButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  autoAdjustNotification: {
    backgroundColor: 'rgba(76, 175, 80, 0.9)',
    borderRadius: 10,
    padding: 10,
    marginTop: 10,
  },
  autoAdjustText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '500',
    textAlign: 'center',
  },
});
