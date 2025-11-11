import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for SMS operations
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Extension for LogLevel to get display name
extension LogLevelExtension on LogLevel {
  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
    }
  }

  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

/// Comprehensive logging system for SchedulerSMS
class SmsLogger {
  static final SmsLogger _instance = SmsLogger._internal();
  factory SmsLogger() => _instance;
  SmsLogger._internal();

  /// Minimum log level to display
  LogLevel minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Log history (in-memory, limited to last 1000 entries)
  final List<LogEntry> _logHistory = [];
  static const int _maxLogHistory = 1000;

  /// Custom log handlers (e.g., for sending logs to analytics)
  final List<Function(LogEntry)> _logHandlers = [];

  /// Add a custom log handler
  void addLogHandler(Function(LogEntry) handler) {
    _logHandlers.add(handler);
  }

  /// Remove a custom log handler
  void removeLogHandler(Function(LogEntry) handler) {
    _logHandlers.remove(handler);
  }

  /// Get log history
  List<LogEntry> get logHistory => List.unmodifiable(_logHistory);

  /// Clear log history
  void clearHistory() {
    _logHistory.clear();
  }

  /// Log a debug message
  void debug(String message, {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, data: data, stackTrace: stackTrace);
  }

  /// Log an info message
  void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }

  /// Log a warning message
  void warning(String message, {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, data: data, stackTrace: stackTrace);
  }

  /// Log an error message
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log a critical error message
  void critical(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(
      LogLevel.critical,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log SMS scheduling event
  void logSchedule({
    required String smsId,
    required String customerId,
    required String customerName,
    required String recipient,
    required DateTime scheduledDate,
  }) {
    info(
      'SMS scheduled',
      data: {
        'smsId': smsId,
        'customerId': customerId,
        'customerName': customerName,
        'recipient': recipient,
        'scheduledDate': scheduledDate.toIso8601String(),
      },
    );
  }

  /// Log SMS sending attempt
  void logSendAttempt({
    required String smsId,
    required String recipient,
    required int attemptNumber,
  }) {
    info(
      'Attempting to send SMS',
      data: {
        'smsId': smsId,
        'recipient': recipient,
        'attemptNumber': attemptNumber,
      },
    );
  }

  /// Log SMS sent successfully
  void logSendSuccess({
    required String smsId,
    required String recipient,
    required DateTime sentAt,
  }) {
    info(
      'SMS sent successfully',
      data: {
        'smsId': smsId,
        'recipient': recipient,
        'sentAt': sentAt.toIso8601String(),
      },
    );
  }

  /// Log SMS send failure
  void logSendFailure({
    required String smsId,
    required String recipient,
    required String errorMessage,
    StackTrace? stackTrace,
  }) {
    error(
      'Failed to send SMS',
      data: {
        'smsId': smsId,
        'recipient': recipient,
        'errorMessage': errorMessage,
      },
      stackTrace: stackTrace,
    );
  }

  /// Log SMS cancellation
  void logCancellation({
    required String smsId,
    required String reason,
  }) {
    info(
      'SMS cancelled',
      data: {
        'smsId': smsId,
        'reason': reason,
      },
    );
  }

  /// Log database operation
  void logDatabaseOperation({
    required String operation,
    required String table,
    Map<String, dynamic>? data,
  }) {
    debug(
      'Database operation: $operation on $table',
      data: data,
    );
  }

  /// Log permission request
  void logPermissionRequest({
    required String permission,
    required bool granted,
  }) {
    info(
      'Permission request: $permission',
      data: {
        'permission': permission,
        'granted': granted,
      },
    );
  }

  /// Log background task execution
  void logBackgroundTask({
    required String taskName,
    required bool success,
    Map<String, dynamic>? data,
  }) {
    if (success) {
      info(
        'Background task completed: $taskName',
        data: data,
      );
    } else {
      error(
        'Background task failed: $taskName',
        data: data,
      );
    }
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Check if we should log this level
    if (level.index < minimumLevel.index) return;

    // Create log entry
    final entry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    // Add to history
    _logHistory.add(entry);
    if (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }

    // Call custom handlers
    for (final handler in _logHandlers) {
      try {
        handler(entry);
      } catch (e) {
        // Ignore handler errors to prevent infinite loops
      }
    }

    // Format and print log
    final formattedMessage = _formatLogEntry(entry);
    
    // Use developer.log for better integration with Flutter DevTools
    developer.log(
      formattedMessage,
      name: 'SchedulerSms',
      level: _getLevelValue(level),
      error: error,
      stackTrace: stackTrace,
    );

    // Also print to console in debug mode
    if (kDebugMode) {
      print(formattedMessage);
    }
  }

  /// Format log entry for display
  String _formatLogEntry(LogEntry entry) {
    final buffer = StringBuffer();
    
    // Add timestamp and level
    buffer.write('[${entry.timestamp.toIso8601String()}] ');
    buffer.write('${entry.level.emoji} ${entry.level.name}: ');
    buffer.write(entry.message);

    // Add data if present
    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.write('\n  Data: ${entry.data}');
    }

    // Add error if present
    if (entry.error != null) {
      buffer.write('\n  Error: ${entry.error}');
    }

    // Add stack trace if present (only first 3 lines in production)
    if (entry.stackTrace != null) {
      final stackLines = entry.stackTrace.toString().split('\n');
      final linesToShow = kDebugMode ? stackLines : stackLines.take(3);
      buffer.write('\n  Stack trace:\n    ${linesToShow.join('\n    ')}');
    }

    return buffer.toString();
  }

  /// Get numeric level value for developer.log
  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  /// Export logs as JSON
  String exportLogsAsJson() {
    return _logHistory.map((entry) => entry.toJson()).toList().toString();
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logHistory.where((entry) => entry.level == level).toList();
  }

  /// Get logs in time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logHistory
        .where((entry) =>
            entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList();
  }

  /// Get error logs
  List<LogEntry> getErrorLogs() {
    return _logHistory
        .where((entry) =>
            entry.level == LogLevel.error || entry.level == LogLevel.critical)
        .toList();
  }
}

/// Represents a single log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'data': data,
    };
  }

  @override
  String toString() {
    return 'LogEntry(level: ${level.name}, message: $message, timestamp: $timestamp)';
  }
}
