import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/sms_database.dart';
import '../models/customer.dart';
import '../models/scheduled_sms.dart';
import '../models/sms_status.dart';
import '../schedulersms_service.dart';
import '../schedulersms_web.dart';
import 'sms_logger.dart';

/// Structured result for diagnostics run.
class SchedulerSmsDiagnosticsResult {
  /// Ordered list of informational log messages captured during diagnostics.
  final List<String> logs;

  /// Ordered list of errors captured during diagnostics. Empty when successful.
  final List<String> errors;

  /// Additional contextual metadata captured during the diagnostics session.
  final Map<String, dynamic> metadata;

  SchedulerSmsDiagnosticsResult({
    required this.logs,
    required this.errors,
    required this.metadata,
  });

  /// Convenience getter indicating whether diagnostics completed without errors.
  bool get success => errors.isEmpty;

  /// Convert the diagnostics result into a console-friendly multi-line string.
  String toConsoleString() {
    final buffer = StringBuffer()
      ..writeln('=== SchedulerSms Diagnostics Report ===')
      ..writeln('Timestamp: ${metadata['timestamp']}')
      ..writeln('Platform: ${metadata['platform']}')
      ..writeln('Scheduler: ${metadata['scheduler']}')
      ..writeln('Success: ${success ? 'yes' : 'no'}');

    if (metadata.containsKey('details')) {
      buffer.writeln('Details: ${metadata['details']}');
    }

    if (logs.isNotEmpty) {
      buffer.writeln('\n-- Steps --');
      for (final log in logs) {
        buffer.writeln(' • $log');
      }
    }

    if (errors.isNotEmpty) {
      buffer.writeln('\n-- Errors --');
      for (final error in errors) {
        buffer.writeln(' • $error');
      }
    }

    if (metadata.containsKey('smsLogger')) {
      buffer.writeln('\n-- SmsLogger (latest entries) --');
      for (final entry in metadata['smsLogger'] as List<String>) {
        buffer.writeln(entry);
      }
    }

    return buffer.toString();
  }

  /// Convert the diagnostics result into a serializable map structure.
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'logs': logs,
      'errors': errors,
      'metadata': metadata,
    };
  }

  @override
  String toString() => toConsoleString();
}

/// Utility runner that exercises SchedulerSms behaviours and surfaces errors.
class SchedulerSmsDiagnostics {
  /// Execute diagnostics against the most appropriate scheduler for the platform.
  ///
  /// When [forceWebScheduler] is true, diagnostics run against [SchedulerSmsWeb]
  /// regardless of the platform. When false (default), the web scheduler is used
  /// only when the app is running on web. Diagnostics always simulate sending and
  /// never attempt to deliver real SMS messages.
  static Future<SchedulerSmsDiagnosticsResult> run({
    bool? forceWebScheduler,
    Duration scheduleOffset = const Duration(minutes: 2),
    String testRecipient = '+15555550123',
    String testMessage = 'SchedulerSms diagnostics message',
  }) async {
    final logs = <String>[];
    final errors = <String>[];
    final logger = SmsLogger();
    final baselineLength = logger.logHistory.length;

    void log(String message) {
      final formatted = '[SchedulerSmsDiagnostics] $message';
      debugPrint(formatted);
      logs.add(message);
    }

    void recordError(String context, Object error, [StackTrace? stackTrace]) {
      final message = '$context: $error';
      final formatted = '[SchedulerSmsDiagnostics][ERROR] $message';
      debugPrint(formatted);
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
      errors.add(message);
    }

    final bool useWebScheduler = forceWebScheduler ?? kIsWeb;
    final metadata = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'scheduler': useWebScheduler ? 'web' : 'service',
      'scheduleOffsetMinutes': scheduleOffset.inMinutes,
    };

    final database = SmsDatabase();
    ScheduledSMS? scheduledSms;

    Future<void> captureStep(String description, Future<void> Function() action) async {
      log('➡️ $description');
      try {
        await action();
        log('✅ $description');
      } catch (e, stack) {
        recordError('$description failed', e, stack);
      }
    }

    if (useWebScheduler) {
      final scheduler = SchedulerSmsWeb();
      await captureStep('Initializing SchedulerSmsWeb', () async {
        await scheduler.initialize(customSmsSender: (sms) async {
          log('Simulating web SMS send for ${sms.id} -> ${sms.recipient}');
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return true;
        });
      });

      await captureStep('Scheduling SMS via web scheduler', () async {
        final customer = Customer(
          id: 'diagnostics-web-customer',
          name: 'Diagnostics Customer',
          phoneNumber: testRecipient,
          createdAt: DateTime.now(),
        );

        scheduledSms = await scheduler.scheduleSms(
          customer: customer,
          message: '$testMessage @${DateTime.now().toIso8601String()}',
          scheduledDate: DateTime.now().add(scheduleOffset),
          tags: const ['diagnostics', 'web'],
          priority: 1,
        );
      });

      if (scheduledSms != null) {
        await captureStep('Updating scheduled SMS on web', () async {
          scheduledSms = await scheduler.updateScheduledSms(
            id: scheduledSms!.id,
            message: '${scheduledSms!.message} (updated)',
            scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
          );
        });

        await captureStep('Disabling scheduled SMS on web', () async {
          await scheduler.disableScheduledSms(scheduledSms!.id);
        });

        await captureStep('Re-enabling scheduled SMS on web', () async {
          await scheduler.enableScheduledSms(scheduledSms!.id);
        });

        await captureStep('Running pending check on web scheduler', () async {
          // Force the message into the past so it is eligible for sending.
          await scheduler.updateScheduledSms(
            id: scheduledSms!.id,
            scheduledDate: DateTime.now().subtract(const Duration(minutes: 1)),
          );
          await scheduler.checkAndSendPendingSms();
        });

        await captureStep('Cancelling scheduled SMS on web', () async {
          await scheduler.cancelScheduledSms(scheduledSms!.id, reason: 'Diagnostics complete');
        });

        await captureStep('Deleting scheduled SMS on web', () async {
          await scheduler.deleteScheduledSms(scheduledSms!.id);
        });
      }

      scheduler.dispose();
    } else {
      final scheduler = SchedulerSmsService();

      await captureStep('Initializing SchedulerSmsService', () async {
        await scheduler.initialize();
      });

      await captureStep('Scheduling SMS via service', () async {
        scheduledSms = await scheduler.scheduleSms(
          recipient: testRecipient,
          message: '$testMessage @${DateTime.now().toIso8601String()}',
          scheduledDate: DateTime.now().add(scheduleOffset),
          tags: const ['diagnostics', 'mobile'],
          priority: 1,
        );
      });

      if (scheduledSms != null) {
        await captureStep('Fetching scheduled SMS', () async {
          await scheduler.getScheduledSms(scheduledSms!.id);
        });

        await captureStep('Updating scheduled SMS message', () async {
          scheduledSms = await scheduler.updateScheduledSms(
            id: scheduledSms!.id,
            message: '${scheduledSms!.message} (updated)',
          );
        });

        await captureStep('Disabling scheduled SMS', () async {
          await scheduler.disableScheduledSms(scheduledSms!.id);
        });

        await captureStep('Re-enabling scheduled SMS', () async {
          await scheduler.enableScheduledSms(scheduledSms!.id);
        });

        await captureStep('Advancing scheduled SMS into the past', () async {
          scheduledSms = await scheduler.updateScheduledSms(
            id: scheduledSms!.id,
            scheduledDate: DateTime.now().subtract(const Duration(minutes: 1)),
          );
        });

        await captureStep('Running pending check on service scheduler', () async {
          await scheduler.checkAndSendPendingSms();
        });

        await captureStep('Cancelling scheduled SMS', () async {
          await scheduler.cancelScheduledSms(scheduledSms!.id);
        });

        await captureStep('Deleting scheduled SMS', () async {
          await scheduler.deleteScheduledSms(scheduledSms!.id);
        });
      }

      scheduler.dispose();
    }

    await captureStep('Collecting diagnostics metadata', () async {
      final allItems = await database.getAllScheduledSms();
      final failedItems = await database.getSmsByStatus(SmsStatus.failed);
      metadata['remainingItems'] = allItems.length;
      metadata['failedItems'] = failedItems.length;
      metadata['details'] =
          'remaining=${allItems.length}, failed=${failedItems.length} after diagnostics';
    });

    final recentLoggerEntries = logger.logHistory.skip(baselineLength).toList();
    metadata['smsLogger'] = recentLoggerEntries.take(10).map((entry) {
      final data = entry.toJson();
      final level = data['level'];
      final message = data['message'];
      return '[${data['timestamp']}] $level: $message${data['error'] != null ? ' | error: ${data['error']}' : ''}';
    }).toList();
    metadata['errorsDetected'] = errors.length;
    metadata['logsCaptured'] = logs.length;

    return SchedulerSmsDiagnosticsResult(
      logs: logs,
      errors: errors,
      metadata: metadata,
    );
  }
}

/// Convenience helper that delegates to [SchedulerSmsDiagnostics.run].
Future<SchedulerSmsDiagnosticsResult> runSchedulerSmsDiagnostics({
  bool? forceWebScheduler,
  Duration scheduleOffset = const Duration(minutes: 2),
  String testRecipient = '+15555550123',
  String testMessage = 'SchedulerSms diagnostics message',
}) {
  return SchedulerSmsDiagnostics.run(
    forceWebScheduler: forceWebScheduler,
    scheduleOffset: scheduleOffset,
    testRecipient: testRecipient,
    testMessage: testMessage,
  );
}
