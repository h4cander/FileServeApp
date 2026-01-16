import 'package:flutter/material.dart';
import 'package:file_serve_app/services/file_server.dart';
import 'package:file_serve_app/services/logger_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileServer _fileServer = FileServer();
  final LoggerService _logger = LoggerService();
  bool _isRunning = false;
  String _serverStatus = '未啟動';
  String _serverUrl = '';
  List<String> _logs = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadLogs();
  }

  Future<void> _requestPermissions() async {
    // Request storage permissions for Android 14+
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  Future<void> _loadLogs() async {
    final logs = await _logger.getLogsForDate(_selectedDate);
    setState(() {
      _logs = logs.reversed.toList(); // Reverse chronological order
    });
  }

  Future<void> _startServer() async {
    try {
      setState(() {
        _serverStatus = '啟動中...';
      });

      final url = await _fileServer.start(_logger);
      
      setState(() {
        _isRunning = true;
        _serverStatus = '運行中';
        _serverUrl = url;
      });

      await _logger.log('系統', 'Server started at $url');
      await _loadLogs();
    } catch (e) {
      setState(() {
        _serverStatus = '啟動失敗: $e';
      });
    }
  }

  Future<void> _stopServer() async {
    await _fileServer.stop();
    setState(() {
      _isRunning = false;
      _serverStatus = '未啟動';
      _serverUrl = '';
    });
    await _logger.log('系統', 'Server stopped');
    await _loadLogs();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('文件伺服器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _startServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('開始', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? _stopServer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('停止', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Server status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '狀態: $_serverStatus',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_serverUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'URL: $_serverUrl',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date selector and logs
            Row(
              children: [
                const Text('日誌日期:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadLogs,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Logs list
            Expanded(
              child: Card(
                child: _logs.isEmpty
                    ? const Center(child: Text('無日誌記錄'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              _logs[index],
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fileServer.stop();
    super.dispose();
  }
}
