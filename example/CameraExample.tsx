import React, { useState, useEffect, useCallback } from 'react';
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
  Platform,
  ScrollView,
} from 'react-native';
import ReactNativeMediapipePose, {
  ReactNativeMediapipePoseView,
  CameraType,
  PoseDetectionResult,
  FrameProcessingInfo,
  DeviceCapability,
} from 'react-native-mediapipe-pose';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

// MediaPipe BlazePose landmark names for debugging
const POSE_LANDMARK_NAMES = [
  'nose',
  'left_eye_inner',
  'left_eye',
  'left_eye_outer',
  'right_eye_inner',
  'right_eye',
  'right_eye_outer',
  'left_ear',
  'right_ear',
  'mouth_left',
  'mouth_right',
  'left_shoulder',
  'right_shoulder',
  'left_elbow',
  'right_elbow',
  'left_wrist',
  'right_wrist',
  'left_pinky',
  'right_pinky',
  'left_index',
  'right_index',
  'left_thumb',
  'right_thumb',
  'left_hip',
  'right_hip',
  'left_knee',
  'right_knee',
  'left_ankle',
  'right_ankle',
  'left_heel',
  'right_heel',
  'left_foot_index',
  'right_foot_index',
];

export default function CameraExample() {
  const [cameraType, setCameraType] = useState<CameraType>('front');
  const [permissionStatus, setPermissionStatus] = useState<string>('unknown');
  const [cameraReady, setCameraReady] = useState<boolean>(false);
  const [lastError, setLastError] = useState<string | null>(null);
  const [isPoseDetectionEnabled, setIsPoseDetectionEnabled] =
    useState<boolean>(false); // Disabled by default
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

  // Performance optimization controls
  const [enablePoseDataStreaming, setEnablePoseDataStreaming] =
    useState<boolean>(false); // Disabled by default for performance
  const [poseDataThrottleMs, setPoseDataThrottleMs] = useState<number>(100); // 100ms throttle default
  const [enableDetailedLogs, setEnableDetailedLogs] = useState<boolean>(false); // Disabled by default for performance
  const [fpsChangeThreshold, setFpsChangeThreshold] = useState<number>(2.0); // 2 FPS change threshold
  const [fpsReportThrottleMs, setFpsReportThrottleMs] = useState<number>(500); // 500ms FPS report throttle
  const [showPerformanceControls, setShowPerformanceControls] =
    useState<boolean>(false); // Performance controls visibility

  const [poseServiceLogs, setPoseServiceLogs] = useState<string[]>([]);
  const [lastPoseServiceError, setLastPoseServiceError] = useState<
    string | null
  >(null);
  const [showDebugLogs, setShowDebugLogs] = useState<boolean>(false);
  const [gpuStatus, setGpuStatus] = useState<{
    isUsingGPU: boolean;
    delegate: string;
    processingUnit: string;
    deviceTier: string;
  } | null>(null);

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
      `🎯 Pose detected with ${landmarks.length} landmarks, processing time: ${procTime}ms`
    );

    // Print detected keypoints for debugging
    console.log('📍 Detected Keypoints:');
    landmarks.forEach((landmark, index) => {
      const { x, y, z, visibility } = landmark;
      const landmarkName = POSE_LANDMARK_NAMES[index] || `landmark_${index}`;
      if (visibility > 0.5) {
        // Only log visible landmarks
        console.log(
          `  ${landmarkName} (${index}): x=${x.toFixed(3)}, y=${y.toFixed(3)}, z=${z.toFixed(3)}, visibility=${visibility.toFixed(3)}`
        );
      }
    });

    // Log visible landmarks count
    const visibleLandmarks = landmarks.filter((l) => l.visibility > 0.5);
    console.log(
      `👁️ Visible landmarks: ${visibleLandmarks.length}/${landmarks.length}`
    );

    // Log key body parts for quick reference
    const keyLandmarks = [
      { name: 'nose', index: 0 },
      { name: 'left_shoulder', index: 11 },
      { name: 'right_shoulder', index: 12 },
      { name: 'left_elbow', index: 13 },
      { name: 'right_elbow', index: 14 },
      { name: 'left_wrist', index: 15 },
      { name: 'right_wrist', index: 16 },
      { name: 'left_hip', index: 23 },
      { name: 'right_hip', index: 24 },
      { name: 'left_knee', index: 25 },
      { name: 'right_knee', index: 26 },
      { name: 'left_ankle', index: 27 },
      { name: 'right_ankle', index: 28 },
    ];

    console.log('🦴 Key Body Parts:');
    keyLandmarks.forEach(({ name, index }) => {
      if (index < landmarks.length) {
        const landmark = landmarks[index];
        if (landmark.visibility > 0.5) {
          console.log(
            `  ${name}: (${landmark.x.toFixed(2)}, ${landmark.y.toFixed(2)}) visibility: ${landmark.visibility.toFixed(2)}`
          );
        }
      }
    });
  };

  const togglePoseDetection = () => {
    const newState = !isPoseDetectionEnabled;
    setIsPoseDetectionEnabled(newState);
    console.log(
      `🎯 Pose detection toggled: ${newState ? 'ENABLED' : 'DISABLED'}`
    );
    if (newState) {
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

  const handleGPUStatus = ({
    nativeEvent: status,
  }: {
    nativeEvent: {
      isUsingGPU: boolean;
      delegate: string;
      processingUnit: string;
      deviceTier: string;
    };
  }) => {
    console.log('🚀 GPU Status detected:', status);
    setGpuStatus(status);

    // Show an alert about the acceleration status
    const accelerationType = status.isUsingGPU ? 'GPU/Neural Engine' : 'CPU';
    const performanceLevel = status.isUsingGPU
      ? 'Maximum Accuracy'
      : 'Standard';
    console.log(
      `🎯 Pose detection running on ${accelerationType} for ${performanceLevel}`
    );
  };

  const adjustFPS = (newFPS: number) => {
    const clampedFPS = Math.max(5, Math.min(60, newFPS));
    setTargetFPS(clampedFPS);
  };

  const toggleFPSControls = () => {
    setShowFPSControls(!showFPSControls);
  };

  const togglePerformanceControls = () => {
    setShowPerformanceControls(!showPerformanceControls);
  };

  const handlePoseServiceLog = ({
    nativeEvent: { message, level, timestamp },
  }: {
    nativeEvent: { message: string; level: string; timestamp: number };
  }) => {
    console.log(`[${level.toUpperCase()}] ${message}`);
    setPoseServiceLogs((prev) => [
      ...prev.slice(-49), // Keep last 49 logs to allow for 50 total
      `[${new Date(timestamp * 1000).toLocaleTimeString()}] ${message}`,
    ]);
  };

  const handlePoseServiceError = ({
    nativeEvent: { error, processingTime },
  }: {
    nativeEvent: { error: string; processingTime: number };
  }) => {
    console.error(`Pose Service Error: ${error} (${processingTime}ms)`);
    setLastPoseServiceError(`${error} (${processingTime}ms)`);

    // Clear error after 5 seconds
    setTimeout(() => setLastPoseServiceError(null), 5000);
  };

  // Modal handlers with useCallback to prevent crashes
  const closeDebugModal = useCallback(() => {
    try {
      setShowDebugLogs(false);
    } catch (error) {
      console.error('Error closing debug modal:', error);
    }
  }, []);

  const clearDebugLogs = useCallback(() => {
    try {
      setPoseServiceLogs([]);
      setLastPoseServiceError(null);
      setShowDebugLogs(false);
    } catch (error) {
      console.error('Error clearing debug logs:', error);
    }
  }, []);

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
        enablePoseDataStreaming={enablePoseDataStreaming}
        poseDataThrottleMs={poseDataThrottleMs}
        enableDetailedLogs={enableDetailedLogs}
        fpsChangeThreshold={fpsChangeThreshold}
        fpsReportThrottleMs={fpsReportThrottleMs}
        targetFPS={targetFPS}
        autoAdjustFPS={autoAdjustFPS}
        onCameraReady={handleCameraReady}
        onError={handleCameraError}
        onFrameProcessed={handleFrameProcessed}
        onPoseDetected={handlePoseDetected}
        onDeviceCapability={handleDeviceCapability}
        onPoseServiceLog={handlePoseServiceLog}
        onPoseServiceError={handlePoseServiceError}
        onGPUStatus={handleGPUStatus}
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

            {/* GPU Status */}
            {gpuStatus && (
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Processing</Text>
                <Text
                  style={[
                    styles.statValue,
                    { color: gpuStatus.isUsingGPU ? '#4CAF50' : '#FF9800' },
                  ]}
                >
                  {gpuStatus.isUsingGPU ? '🚀 GPU' : '🔄 CPU'}
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

          {/* Performance Controls */}
          {showPerformanceControls && (
            <View style={styles.fpsControls}>
              <Text style={styles.fpsControlsTitle}>
                ⚡ Performance Optimization
              </Text>

              {/* Pose Data Streaming Toggle */}
              <View style={styles.autoAdjustContainer}>
                <Text style={styles.autoAdjustLabel}>Stream Pose Data:</Text>
                <TouchableOpacity
                  style={[
                    styles.toggleButton,
                    enablePoseDataStreaming && styles.toggleButtonActive,
                  ]}
                  onPress={() =>
                    setEnablePoseDataStreaming(!enablePoseDataStreaming)
                  }
                >
                  <Text style={styles.toggleButtonText}>
                    {enablePoseDataStreaming ? 'ON' : 'OFF'}
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Detailed Logs Toggle */}
              <View style={styles.autoAdjustContainer}>
                <Text style={styles.autoAdjustLabel}>Detailed Logs:</Text>
                <TouchableOpacity
                  style={[
                    styles.toggleButton,
                    enableDetailedLogs && styles.toggleButtonActive,
                  ]}
                  onPress={() => setEnableDetailedLogs(!enableDetailedLogs)}
                >
                  <Text style={styles.toggleButtonText}>
                    {enableDetailedLogs ? 'ON' : 'OFF'}
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Throttle Controls (only when streaming is enabled) */}
              {enablePoseDataStreaming && (
                <View>
                  <Text style={styles.autoAdjustLabel}>
                    Data Throttle (ms):
                  </Text>
                  <View style={styles.fpsButtons}>
                    {[50, 100, 200].map((throttleValue) => (
                      <TouchableOpacity
                        key={throttleValue}
                        style={[
                          styles.fpsButton,
                          poseDataThrottleMs === throttleValue &&
                            styles.fpsButtonActive,
                        ]}
                        onPress={() => setPoseDataThrottleMs(throttleValue)}
                      >
                        <Text style={styles.fpsButtonText}>
                          {throttleValue}
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                </View>
              )}

              <Text style={styles.deviceInfo}>
                💡 Disable streaming for maximum performance
                {enablePoseDataStreaming &&
                  ` • Throttle: ${poseDataThrottleMs}ms`}
              </Text>
            </View>
          )}

          {/* Debug Logs Toggle */}
          {(poseServiceLogs.length > 0 || lastPoseServiceError) && (
            <TouchableOpacity
              style={styles.debugToggleButton}
              onPress={() => setShowDebugLogs(true)}
            >
              <Text style={styles.debugToggleText}>
                🔍 Show Logs{' '}
                {lastPoseServiceError
                  ? '(Error)'
                  : `(${poseServiceLogs.length})`}
              </Text>
            </TouchableOpacity>
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

          <TouchableOpacity
            style={styles.controlButton}
            onPress={togglePerformanceControls}
          >
            <Text style={styles.controlButtonText}>🚀</Text>
            <Text style={styles.controlButtonLabel}>Perf</Text>
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

      {/* Debug Logs Modal */}
      {showDebugLogs && (
        <TouchableOpacity
          style={styles.debugModalOverlay}
          activeOpacity={1}
          onPress={closeDebugModal}
        >
          <TouchableOpacity
            style={styles.debugModal}
            activeOpacity={1}
            onPress={(e) => e.stopPropagation()}
          >
            <View style={styles.debugModalHeader}>
              <Text style={styles.debugModalTitle}>
                🔍 Pose Service Debug Logs
              </Text>
              <TouchableOpacity
                style={styles.debugCloseButton}
                onPress={closeDebugModal}
              >
                <Text style={styles.debugCloseText}>✕</Text>
              </TouchableOpacity>
            </View>

            {lastPoseServiceError && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>❌ {lastPoseServiceError}</Text>
              </View>
            )}

            {poseServiceLogs.length > 0 ? (
              <View style={styles.logsContainer}>
                <Text style={styles.logsHeader}>
                  Recent Logs ({poseServiceLogs.length}):
                </Text>
                <ScrollView
                  style={styles.logsScrollView}
                  showsVerticalScrollIndicator={true}
                  nestedScrollEnabled={true}
                >
                  {poseServiceLogs.map((log, index) => (
                    <Text key={index} style={styles.logText}>
                      {log}
                    </Text>
                  ))}
                </ScrollView>
              </View>
            ) : (
              !lastPoseServiceError && (
                <View style={styles.logsContainer}>
                  <Text style={styles.logsHeader}>No logs available</Text>
                  <Text style={styles.logText}>
                    Waiting for pose detection service logs...
                  </Text>
                </View>
              )
            )}

            <TouchableOpacity
              style={styles.debugClearButton}
              onPress={clearDebugLogs}
            >
              <Text style={styles.debugClearText}>Clear Logs</Text>
            </TouchableOpacity>
          </TouchableOpacity>
        </TouchableOpacity>
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
  debugOverlay: {
    position: 'absolute',
    top: 50,
    right: 10,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    borderRadius: 10,
    padding: 10,
    maxWidth: 300,
    zIndex: 100,
  },
  debugTitle: {
    color: '#4CAF50',
    fontSize: 14,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  debugToggleButton: {
    backgroundColor: 'rgba(76, 175, 80, 0.8)',
    borderRadius: 15,
    padding: 8,
    marginTop: 10,
    alignItems: 'center',
  },
  debugToggleText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  debugModalOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  debugModal: {
    backgroundColor: '#1a1a1a',
    borderRadius: 20,
    padding: 20,
    width: '90%',
    maxHeight: '85%',
    minHeight: '40%',
    borderWidth: 2,
    borderColor: '#4CAF50',
  },
  debugModalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },
  debugModalTitle: {
    color: '#4CAF50',
    fontSize: 18,
    fontWeight: 'bold',
  },
  debugCloseButton: {
    backgroundColor: 'rgba(244, 67, 54, 0.8)',
    borderRadius: 15,
    width: 30,
    height: 30,
    justifyContent: 'center',
    alignItems: 'center',
  },
  debugCloseText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  debugClearButton: {
    backgroundColor: '#FF9800',
    borderRadius: 10,
    padding: 12,
    alignItems: 'center',
    marginTop: 15,
  },
  debugClearText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  logsHeader: {
    color: '#4CAF50',
    fontSize: 14,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  errorContainer: {
    backgroundColor: 'rgba(244, 67, 54, 0.2)',
    borderRadius: 6,
    padding: 8,
    marginBottom: 8,
  },
  errorText: {
    color: '#FF5252',
    fontSize: 12,
    fontWeight: '500',
  },
  logsContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 6,
    padding: 8,
    maxHeight: 300,
    minHeight: 150,
  },
  logsScrollView: {
    maxHeight: 250,
    minHeight: 120,
  },
  logText: {
    color: '#E0E0E0',
    fontSize: 11,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    marginBottom: 3,
    lineHeight: 14,
  },
});
