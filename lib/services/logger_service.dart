import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggerService {
  Future<void> log(String ip, String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd');
      final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final logFileName = '${dateFormat.format(now)}.log';
      final logFile = File('${logsDir.path}/$logFileName');

      final logEntry = '[${timeFormat.format(now)}] $ip - $message\n';
      
      await logFile.writeAsString(
        logEntry,
        mode: FileMode.append,
      );
    } catch (e) {
      print('Failed to write log: $e');
    }
  }

  Future<List<String>> getLogsForDate(DateTime date) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      
      if (!await logsDir.exists()) {
        return [];
      }

      final dateFormat = DateFormat('yyyyMMdd');
      final logFileName = '${dateFormat.format(date)}.log';
      final logFile = File('${logsDir.path}/$logFileName');

      if (!await logFile.exists()) {
        return [];
      }

      final contents = await logFile.readAsString();
      return contents.split('\n').where((line) => line.isNotEmpty).toList();
    } catch (e) {
      print('Failed to read logs: $e');
      return [];
    }
  }
}
