import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/scheduled_sms.dart';
import 'models/sms_status.dart';
import 'models/customer.dart';
import 'database/sms_database.dart';
import 'utils/sms_logger.dart';

/// Web-compatible SMS scheduler service
/// 
/// On web platforms, SMS cannot be sent directly. Instead, this implementation
/// provides integration points for web-based SMS APIs (like Twilio, etc.)
class SchedulerSmsWeb {
  static final SchedulerSmsWeb _instance = SchedulerSmsWeb._internal();
  final SmsDatabase _database = SmsDatabase();
  final SmsLogger _logger = SmsLogger();

  /// Stream controller for SMS status updates
  final _statusController = StreamController<ScheduledSMS>.broadcast();

  /// Callback for web-based SMS sending
  /// This should be set by the application to integrate with their SMS API
  Future<bool> Function(ScheduledSMS sms)? webSmsSender;

  factory SchedulerSmsWeb() => _instance;

  SchedulerSmsWeb._internal();

  /// Stream of SMS status updates
  Stream<ScheduledSMS> get statusStream => _statusController.stream;

  /// Initialize the web SMS scheduler
  Future<void> initialize({
    Future<bool> Function(ScheduledSMS sms)? customSmsSender,
  }) async {
    _logger.info('Initializing SchedulerSMS for Web');
    
    if (customSmsSender != null) {
      webSmsSender = customSmsSender;
      _logger.info('Custom SMS sender registered');
    } else {
      _logger.warning(
        'No custom SMS sender provided. SMS sending will not work on web. '
        'Please provide a webSmsSender function that integrates with your SMS API.',
      );
    }

    // Start periodic check for pending messages
    _startPeriodicCheck();
  }

  /// Start periodic check for pending SMS messages
  void _startPeriodicCheck() {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        await checkAndSendPendingSms();
      } catch (e, stackTrace) {
        _logger.error(
          'Error in periodic SMS check',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  /// Schedule a new SMS message
  Future<ScheduledSMS> scheduleSms({
    required Customer customer,
    required String message,
    required DateTime scheduledDate,
    bool active = true,
    List<String> tags = const [],
    int priority = 3,
  }) async {
    _logger.logSchedule(
      smsId: 'pending',
      customerId: customer.id,
      customerName: customer.name,
      recipient: customer.phoneNumber,
      scheduledDate: scheduledDate,
    );

    final sms = ScheduledSMS(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customer.id,
      customerName: customer.name,
      recipient: customer.phoneNumber,
      message: message,
      scheduledDate: scheduledDate,
      active: active,
      status: SmsStatus.pending,
      createdAt: DateTime.now(),
      tags: tags,
      priority: priority,
    );

    await _database.insertScheduledSms(sms);
    
    _logger.logSchedule(
      smsId: sms.id,
      customerId: customer.id,
      customerName: customer.name,
      recipient: customer.phoneNumber,
      scheduledDate: scheduledDate,
    );

    return sms;
  }

  /// Check and send pending SMS messages
  Future<void> checkAndSendPendingSms() async {
    final pendingSms = await _database.getPendingSms();
    
    _logger.debug(
      'Checking for pending SMS messages',
      data: {'count': pendingSms.length},
    );

    for (final sms in pendingSms) {
      await _sendSms(sms);
    }
  }

  /// Send a single SMS message using the web SMS sender
  Future<void> _sendSms(ScheduledSMS sms) async {
    if (webSmsSender == null) {
      _logger.error(
        'Cannot send SMS: No web SMS sender configured',
        data: {'smsId': sms.id},
      );
      
      await _database.updateSmsStatus(
        sms.id,
        SmsStatus.failed,
        errorMessage: 'No web SMS sender configured. Please provide a webSmsSender function.',
      );
      
      return;
    }

    try {
      _logger.logSendAttempt(
        smsId: sms.id,
        recipient: sms.recipient,
        attemptNumber: sms.retryCount + 1,
      );

      // Update status to sending
      await _database.updateSmsStatus(sms.id, SmsStatus.sending);
      
      final updatedSms = sms.copyWith(
        status: SmsStatus.sending,
        updatedAt: DateTime.now(),
      );
      _statusController.add(updatedSms);

      // Call the web SMS sender
      final success = await webSmsSender!(sms);

      if (success) {
        // Update status to sent
        await _database.updateSmsStatus(
          sms.id,
          SmsStatus.sent,
          sentAt: DateTime.now(),
        );

        final sentSms = sms.copyWith(
          status: SmsStatus.sent,
          sentAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _statusController.add(sentSms);

        _logger.logSendSuccess(
          smsId: sms.id,
          recipient: sms.recipient,
          sentAt: DateTime.now(),
        );
      } else {
        throw Exception('Web SMS sender returned false');
      }
    } catch (e, stackTrace) {
      // Update status to failed
      await _database.updateSmsStatus(
        sms.id,
        SmsStatus.failed,
        errorMessage: e.toString(),
      );

      final failedSms = sms.copyWith(
        status: SmsStatus.failed,
        errorMessage: e.toString(),
        updatedAt: DateTime.now(),
        retryCount: sms.retryCount + 1,
      );
      _statusController.add(failedSms);

      _logger.logSendFailure(
        smsId: sms.id,
        recipient: sms.recipient,
        errorMessage: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all scheduled SMS messages
  Future<List<ScheduledSMS>> getAllScheduledSms() async {
    return await _database.getAllScheduledSms();
  }

  /// Get scheduled SMS messages for a specific customer
  Future<List<ScheduledSMS>> getScheduledSmsForCustomer(String customerId) async {
    final allSms = await _database.getAllScheduledSms();
    return allSms.where((sms) => sms.customerId == customerId).toList();
  }

  /// Update a scheduled SMS
  Future<ScheduledSMS> updateScheduledSms({
    required String id,
    String? message,
    DateTime? scheduledDate,
    bool? active,
    List<String>? tags,
    int? priority,
  }) async {
    final existingSms = await _database.getScheduledSms(id);
    
    if (existingSms == null) {
      throw ArgumentError('Scheduled SMS not found');
    }

    final updatedSms = existingSms.copyWith(
      message: message,
      scheduledDate: scheduledDate,
      active: active,
      tags: tags,
      priority: priority,
      updatedAt: DateTime.now(),
    );

    await _database.updateScheduledSms(updatedSms);
    _statusController.add(updatedSms);

    _logger.info(
      'SMS updated',
      data: {'smsId': id},
    );

    return updatedSms;
  }

  /// Cancel a scheduled SMS
  Future<void> cancelScheduledSms(String id, {String reason = 'User cancelled'}) async {
    await _database.updateSmsStatus(id, SmsStatus.cancelled);
    
    final sms = await _database.getScheduledSms(id);
    if (sms != null) {
      _statusController.add(sms);
    }

    _logger.logCancellation(smsId: id, reason: reason);
  }

  /// Delete a scheduled SMS
  Future<void> deleteScheduledSms(String id) async {
    await _database.deleteScheduledSms(id);
    
    _logger.info(
      'SMS deleted',
      data: {'smsId': id},
    );
  }

  /// Enable a scheduled SMS
  Future<void> enableScheduledSms(String id) async {
    await _database.toggleActive(id, true);
    
    final sms = await _database.getScheduledSms(id);
    if (sms != null) {
      _statusController.add(sms);
    }

    _logger.info(
      'SMS enabled',
      data: {'smsId': id},
    );
  }

  /// Disable a scheduled SMS
  Future<void> disableScheduledSms(String id) async {
    await _database.toggleActive(id, false);
    
    final sms = await _database.getScheduledSms(id);
    if (sms != null) {
      _statusController.add(sms);
    }

    _logger.info(
      'SMS disabled',
      data: {'smsId': id},
    );
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}
