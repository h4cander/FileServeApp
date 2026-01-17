/**
 * File Server App
 * 
 * @format
 */

import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  NativeModules,
  NativeEventEmitter,
  Platform,
  PermissionsAndroid,
  Alert,
} from 'react-native';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';

const { FileServer } = NativeModules;

interface LogEntry {
  time: string;
  ip: string;
  operation: string;
  path: string;
}

function App() {
  return (
    <SafeAreaProvider>
      <AppContent />
    </SafeAreaProvider>
  );
}

function AppContent() {
  const safeAreaInsets = useSafeAreaInsets();
  const [isRunning, setIsRunning] = useState(false);
  const [serverUrl, setServerUrl] = useState('');
  const [logs, setLogs] = useState<string[]>([]);
  const [selectedDate, setSelectedDate] = useState('');
  const [availableDates, setAvailableDates] = useState<string[]>([]);

  useEffect(() => {
    checkPermissions();
    checkServerStatus();
    loadLogDates();
    
    // Setup event listener for new log entries
    const eventEmitter = new NativeEventEmitter(FileServer);
    const subscription = eventEmitter.addListener('newLogEntry', (logEntry: string) => {
      setLogs(prevLogs => [logEntry, ...prevLogs]);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  useEffect(() => {
    if (selectedDate) {
      loadLogs(selectedDate);
    } else if (availableDates.length > 0) {
      const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      setSelectedDate(today);
      loadLogs(today);
    }
  }, [selectedDate, availableDates]);

  const checkPermissions = async () => {
    if (Platform.OS === 'android') {
      try {
        const granted = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
          PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
        ]);

        if (Platform.Version >= 30) {
          // For Android 11+, we need MANAGE_EXTERNAL_STORAGE
          // This requires special handling and user to manually enable in settings
          Alert.alert(
            '檔案權限',
            '請在設定中授予「所有檔案存取權限」以獲得最大檔案存取能力',
            [{ text: '確定' }]
          );
        }
      } catch (err) {
        console.warn(err);
      }
    }
  };

  const checkServerStatus = async () => {
    try {
      const running = await FileServer.isServerRunning();
      setIsRunning(running);
    } catch (error) {
      console.error('Error checking server status:', error);
    }
  };

  const loadLogDates = async () => {
    try {
      const dates = await FileServer.getLogDates();
      setAvailableDates(dates);
    } catch (error) {
      console.error('Error loading log dates:', error);
    }
  };

  const loadLogs = async (date: string) => {
    try {
      const logContent = await FileServer.getLogs(date);
      const logLines = logContent.split('\n').filter((line: string) => line.trim()).reverse();
      setLogs(logLines);
    } catch (error) {
      console.error('Error loading logs:', error);
    }
  };

  const startServer = async () => {
    try {
      const result = await FileServer.startServer(8080);
      setIsRunning(true);
      setServerUrl(result.url);
      Alert.alert('伺服器已啟動', `請在瀏覽器中開啟：\n${result.url}`);
    } catch (error: any) {
      Alert.alert('錯誤', error.message || '無法啟動伺服器');
    }
  };

  const stopServer = async () => {
    try {
      await FileServer.stopServer();
      setIsRunning(false);
      setServerUrl('');
      Alert.alert('伺服器已停止', '伺服器已成功停止');
    } catch (error: any) {
      Alert.alert('錯誤', error.message || '無法停止伺服器');
    }
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr || dateStr.length !== 8) return dateStr;
    return `${dateStr.slice(0, 4)}-${dateStr.slice(4, 6)}-${dateStr.slice(6, 8)}`;
  };

  return (
    <View style={[styles.container, { paddingTop: safeAreaInsets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>📁 File Server</Text>
      </View>

      {/* Control Panel */}
      <View style={styles.controlPanel}>
        <View style={styles.buttonRow}>
          <TouchableOpacity
            style={[styles.button, styles.startButton, isRunning && styles.buttonDisabled]}
            onPress={startServer}
            disabled={isRunning}
          >
            <Text style={styles.buttonText}>▶️ 開始服務</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.stopButton, !isRunning && styles.buttonDisabled]}
            onPress={stopServer}
            disabled={!isRunning}
          >
            <Text style={styles.buttonText}>⏹️ 停止服務</Text>
          </TouchableOpacity>
        </View>

        {/* Status Display */}
        <View style={styles.statusContainer}>
          <View style={[styles.statusIndicator, isRunning && styles.statusActive]} />
          <Text style={styles.statusText}>
            {isRunning ? '運行中' : '已停止'}
          </Text>
        </View>

        {serverUrl ? (
          <View style={styles.urlContainer}>
            <Text style={styles.urlLabel}>伺服器地址:</Text>
            <Text style={styles.urlText}>{serverUrl}</Text>
          </View>
        ) : null}
      </View>

      {/* Date Selector */}
      <View style={styles.dateSelector}>
        <Text style={styles.sectionTitle}>日誌日期:</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.dateScroll}>
          {availableDates.map((date) => (
            <TouchableOpacity
              key={date}
              style={[styles.dateButton, selectedDate === date && styles.dateButtonActive]}
              onPress={() => setSelectedDate(date)}
            >
              <Text style={[styles.dateButtonText, selectedDate === date && styles.dateButtonTextActive]}>
                {formatDate(date)}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      {/* Logs */}
      <View style={styles.logsContainer}>
        <Text style={styles.sectionTitle}>操作日誌 (最新在上):</Text>
        <ScrollView style={styles.logScroll}>
          {logs.length === 0 ? (
            <Text style={styles.emptyLog}>目前沒有日誌記錄</Text>
          ) : (
            logs.map((log, index) => {
              const parts = log.split(' | ');
              return (
                <View key={index} style={styles.logEntry}>
                  <Text style={styles.logTime}>{parts[0]}</Text>
                  <Text style={styles.logIp}>{parts[1]}</Text>
                  <Text style={styles.logOperation}>{parts[2]}</Text>
                  <Text style={styles.logPath}>{parts[3]}</Text>
                </View>
              );
            })
          )}
        </ScrollView>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#4CAF50',
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
  },
  controlPanel: {
    backgroundColor: 'white',
    padding: 20,
    margin: 10,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 10,
  },
  button: {
    flex: 1,
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  startButton: {
    backgroundColor: '#4CAF50',
  },
  stopButton: {
    backgroundColor: '#f44336',
  },
  buttonDisabled: {
    backgroundColor: '#ccc',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 15,
    justifyContent: 'center',
  },
  statusIndicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#ccc',
    marginRight: 8,
  },
  statusActive: {
    backgroundColor: '#4CAF50',
  },
  statusText: {
    fontSize: 16,
    color: '#333',
  },
  urlContainer: {
    marginTop: 15,
    padding: 10,
    backgroundColor: '#f0f0f0',
    borderRadius: 8,
  },
  urlLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 5,
  },
  urlText: {
    fontSize: 14,
    color: '#2196F3',
    fontWeight: 'bold',
  },
  dateSelector: {
    backgroundColor: 'white',
    padding: 15,
    marginHorizontal: 10,
    marginBottom: 10,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
  },
  dateScroll: {
    flexDirection: 'row',
  },
  dateButton: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    backgroundColor: '#f0f0f0',
    borderRadius: 20,
    marginRight: 10,
  },
  dateButtonActive: {
    backgroundColor: '#4CAF50',
  },
  dateButtonText: {
    color: '#333',
    fontSize: 14,
  },
  dateButtonTextActive: {
    color: 'white',
    fontWeight: 'bold',
  },
  logsContainer: {
    flex: 1,
    backgroundColor: 'white',
    margin: 10,
    borderRadius: 10,
    padding: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  logScroll: {
    flex: 1,
  },
  emptyLog: {
    textAlign: 'center',
    color: '#999',
    marginTop: 20,
  },
  logEntry: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  logTime: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  logIp: {
    fontSize: 13,
    color: '#2196F3',
    fontWeight: 'bold',
    marginBottom: 2,
  },
  logOperation: {
    fontSize: 13,
    color: '#4CAF50',
    fontWeight: 'bold',
    marginBottom: 2,
  },
  logPath: {
    fontSize: 12,
    color: '#333',
  },
});

export default App;
