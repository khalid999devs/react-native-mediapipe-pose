import React from 'react';
import CameraExample from './CameraExample';

export default function App() {
  return <CameraExample />;
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: '#eee',
  },
  cameraView: {
    height: 300,
    backgroundColor: '#000',
    borderRadius: 10,
  },
};
