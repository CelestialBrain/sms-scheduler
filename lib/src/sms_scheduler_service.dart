import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart' as telephony;
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';

import 'database/sms_database.dart';
import 'models/customer.dart';
import 'models/scheduled_sms.dart';
import 'models/sms_status.dart';

/// Main service for scheduling and sending SMS messages
class SmsSchedulerService {
  static final SmsSchedulerService _instance = SmsSchedulerService._internal();
  final telephony.Telephony _telephony = telephony.Telephony.instance;
  final SmsDatabase _database = SmsDatabase();
  final _uuid = const Uuid();

  /// Expose the underlying database for advanced use cases (e.g., FlutterFlow)
  SmsDatabase get database => _database;

  /// Stream controller for SMS status updates
  final _statusController = StreamController<ScheduledSMS>.broadcast();

  factory SmsSchedulerService() => _instance;

  SmsSchedulerService._internal();

  /// Stream of SMS status updates
  Stream<ScheduledSMS> get statusStream => _statusController.stream;

  /// Initialize the SMS scheduler service
  Future<void> initialize() async {
    // Request SMS permissions
    final permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    
    if (!permissionsGranted!) {
      throw Exception('SMS permissions not granted');
    }

    // Initialize WorkManager for background tasks
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Register periodic task to check for pending SMS
    await Workmanager().registerPeriodicTask(
      'sms-scheduler-check',
      'checkPendingSms',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }

  /// Schedule a new SMS message
  Future<ScheduledSMS> scheduleSms({
    Customer? customer,
    String? customerId,
    String? customerName,
    String? recipient,
    required String message,
    required DateTime scheduledDate,
    bool active = true,
    List<String> tags = const [],
    int priority = 3,
  }) async {
    final resolvedRecipient = customer?.phoneNumber ?? recipient;
    final resolvedCustomerId = customer?.id ?? customerId;
    final resolvedCustomerName = customer?.name ?? customerName;

    // Validate inputs
    if (resolvedRecipient == null || resolvedRecipient.isEmpty) {
      throw ArgumentError('Recipient cannot be empty');
    }

    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }

    if (scheduledDate.isBefore(DateTime.now())) {
      throw ArgumentError('Scheduled date must be in the future');
    }

    // Create scheduled SMS
    final sms = ScheduledSMS(
      id: _uuid.v4(),
      customerId: resolvedCustomerId,
      customerName: resolvedCustomerName,
      recipient: resolvedRecipient,
      message: message,
      scheduledDate: scheduledDate,
      active: active,
      status: SmsStatus.pending,
      createdAt: DateTime.now(),
      tags: tags,
      priority: priority,
    );

    // Save to database
    await _database.insertScheduledSms(sms);

    // Schedule immediate check if the time is close
    if (scheduledDate.difference(DateTime.now()).inMinutes < 15) {
      await _scheduleImmediateCheck();
    }

    return sms;
  }

  /// Update an existing scheduled SMS
  Future<ScheduledSMS> updateScheduledSms({
    required String id,
    String? recipient,
    String? message,
    DateTime? scheduledDate,
    bool? active,
  }) async {
    final existingSms = await _database.getScheduledSms(id);
    
    if (existingSms == null) {
      throw ArgumentError('Scheduled SMS not found');
    }

    final updatedSms = existingSms.copyWith(
      recipient: recipient,
      message: message,
      scheduledDate: scheduledDate,
      active: active,
      updatedAt: DateTime.now(),
    );

    await _database.updateScheduledSms(updatedSms);
    _statusController.add(updatedSms);

    return updatedSms;
  }

  /// Cancel a scheduled SMS
  Future<void> cancelScheduledSms(String id) async {
    await _database.updateSmsStatus(id, SmsStatus.cancelled);
    
    final sms = await _database.getScheduledSms(id);
    if (sms != null) {
      _statusController.add(sms);
    }
  }

  /// Delete a scheduled SMS
  Future<void> deleteScheduledSms(String id) async {
    await _database.deleteScheduledSms(id);
  }

  /// Enable a scheduled SMS
  Future<void> enableScheduledSms(String id) async {
    await _database.toggleActive(id, true);
    
    final sms = await _database.getScheduledSms(id);
    if (sms != null) {
      _statusController.add(sms);
    }
  }

  /// Disable a scheduled SMS
  Future<void> disableScheduledSms(String id) async {
    await _database.toggleActive(id, false);
    
    final sms = await _database.getScheduledSms(id);
    if (sms != null) {
      _statusController.add(sms);
    }
  }

  /// Get all scheduled SMS messages
  Future<List<ScheduledSMS>> getAllScheduledSms() async {
    return await _database.getAllScheduledSms();
  }

  /// Get active scheduled SMS messages
  Future<List<ScheduledSMS>> getActiveScheduledSms() async {
    return await _database.getActiveScheduledSms();
  }

  /// Get a specific scheduled SMS
  Future<ScheduledSMS?> getScheduledSms(String id) async {
    return await _database.getScheduledSms(id);
  }

  /// Check and send pending SMS messages
  Future<void> checkAndSendPendingSms() async {
    final pendingSms = await _database.getPendingSms();

    for (final sms in pendingSms) {
      await _sendSms(sms);
    }
  }

  /// Send a single SMS message
  Future<void> _sendSms(ScheduledSMS sms) async {
    try {
      // Update status to sending
      await _database.updateSmsStatus(sms.id, SmsStatus.sending);
      
      final updatedSms = sms.copyWith(
        status: SmsStatus.sending,
        updatedAt: DateTime.now(),
      );
      _statusController.add(updatedSms);

      // Send SMS using telephony
      await _telephony.sendSms(
        to: sms.recipient,
        message: sms.message,
      );

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
    } catch (e) {
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
      );
      _statusController.add(failedSms);
    }
  }

  /// Schedule an immediate check for pending SMS
  Future<void> _scheduleImmediateCheck() async {
    await Workmanager().registerOneOffTask(
      'sms-immediate-check-${_uuid.v4()}',
      'checkPendingSms',
      initialDelay: const Duration(seconds: 30),
    );
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = SmsSchedulerService();
      await service.checkAndSendPendingSms();
      return true;
    } catch (e) {
      debugPrint('Error in background task: $e');
      return false;
    }
  });
}
