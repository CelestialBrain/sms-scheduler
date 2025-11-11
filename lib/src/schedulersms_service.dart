import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:telephony/telephony.dart' as telephony;
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';

import 'database/sms_database.dart';
import 'database/customer_database.dart';
import 'models/customer.dart';
import 'models/scheduled_sms.dart';
import 'models/sms_status.dart';
import 'utils/sms_logger.dart';

/// Main service for scheduling and sending SMS messages
class SchedulerSmsService {
  static final SchedulerSmsService _instance = SchedulerSmsService._internal();
  final telephony.Telephony _telephony = telephony.Telephony.instance;
  final SmsDatabase _database = SmsDatabase();
  final CustomerDatabase _customerDatabase = CustomerDatabase();
  final _uuid = const Uuid();
  final SmsLogger _logger = SmsLogger();

  /// Expose the underlying database for advanced use cases (e.g., FlutterFlow)
  SmsDatabase get database => _database;
  
  /// Expose the customer database for advanced use cases
  CustomerDatabase get customerDatabase => _customerDatabase;

  /// Stream controller for SMS status updates
  final _statusController = StreamController<ScheduledSMS>.broadcast();

  factory SchedulerSmsService() => _instance;

  SchedulerSmsService._internal();

  /// Stream of SMS status updates
  Stream<ScheduledSMS> get statusStream => _statusController.stream;

  /// Initialize the SMS scheduler service
  Future<void> initialize() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SchedulerSmsService is not supported on web. Use SchedulerSmsWeb '
        'with a custom SMS sender instead.',
      );
    }

    // Request SMS permissions
    final permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;

    if (!permissionsGranted!) {
      _logger.error('SMS permissions not granted. SchedulerSmsService cannot initialize.');
      throw Exception('SMS permissions not granted');
    }

    if (!_supportsBackgroundTasks) {
      _logger.info(
        'Background tasks are not supported on this platform. Skipping Workmanager setup.',
      );
      return;
    }

    // Initialize WorkManager for background tasks
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      await Workmanager().registerPeriodicTask(
        'schedulersms-check',
        'checkPendingSms',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );

      _logger.info('Workmanager initialized and periodic task registered.');
    } on MissingPluginException catch (e, stackTrace) {
      _logger.warning(
        'Workmanager plugin is not available. Background SMS checks will be disabled.',
        data: {
          'plugin': 'be.tramckrijte.workmanager',
        },
        stackTrace: stackTrace,
      );
      _logger.debug(
        'MissingPluginException details',
        data: {
          'message': e.message,
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize Workmanager. Background SMS checks will be disabled.',
        error: e,
        stackTrace: stackTrace,
      );
    }
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

    _logger.logSchedule(
      smsId: sms.id,
      customerId: resolvedCustomerId ?? 'unknown',
      customerName: resolvedCustomerName ?? 'unknown',
      recipient: resolvedRecipient,
      scheduledDate: scheduledDate,
    );

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

      _logger.logSendAttempt(
        smsId: sms.id,
        recipient: sms.recipient,
        attemptNumber: sms.retryCount + 1,
      );

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

      _logger.logSendSuccess(
        smsId: sms.id,
        recipient: sms.recipient,
        sentAt: DateTime.now(),
      );
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

      _logger.logSendFailure(
        smsId: sms.id,
        recipient: sms.recipient,
        errorMessage: e.toString(),
      );
    }
  }

  /// Schedule an immediate check for pending SMS
  Future<void> _scheduleImmediateCheck() async {
    if (!_supportsBackgroundTasks) {
      _logger.debug(
        'Immediate background check skipped because background tasks are not supported.',
      );
      return;
    }

    try {
      await Workmanager().registerOneOffTask(
        'sms-immediate-check-${_uuid.v4()}',
        'checkPendingSms',
        initialDelay: const Duration(seconds: 30),
      );

      _logger.debug('Immediate background check scheduled via Workmanager.');
    } on MissingPluginException catch (e, stackTrace) {
      _logger.warning(
        'Workmanager plugin unavailable. Immediate background check was not scheduled.',
        data: {
          'plugin': 'be.tramckrijte.workmanager',
        },
        stackTrace: stackTrace,
      );
      _logger.debug(
        'MissingPluginException details',
        data: {
          'message': e.message,
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register immediate background check.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  bool get _supportsBackgroundTasks => !kIsWeb;

  // Customer Management Methods
  
  /// Create a new customer
  Future<Customer> createCustomer({
    required String name,
    required String phoneNumber,
    String? email,
    String? notes,
    List<String> tags = const [],
    Map<String, String> metadata = const {},
  }) async {
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      notes: notes,
      tags: tags,
      metadata: metadata,
      createdAt: DateTime.now(),
      active: true,
    );

    await _customerDatabase.insertCustomer(customer);
    
    _logger.info(
      'Customer created',
      data: {
        'customerId': customer.id,
        'name': customer.name,
        'phoneNumber': customer.phoneNumber,
      },
    );

    return customer;
  }

  /// Get a customer by ID
  Future<Customer?> getCustomer(String id) async {
    return await _customerDatabase.getCustomer(id);
  }

  /// Get a customer by phone number
  Future<Customer?> getCustomerByPhone(String phoneNumber) async {
    return await _customerDatabase.getCustomerByPhone(phoneNumber);
  }

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    return await _customerDatabase.getAllCustomers();
  }

  /// Get active customers
  Future<List<Customer>> getActiveCustomers() async {
    return await _customerDatabase.getActiveCustomers();
  }

  /// Update a customer
  Future<Customer> updateCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    String? email,
    String? notes,
    List<String>? tags,
    Map<String, String>? metadata,
    bool? active,
  }) async {
    final existingCustomer = await _customerDatabase.getCustomer(id);
    
    if (existingCustomer == null) {
      throw ArgumentError('Customer not found');
    }

    final updatedCustomer = existingCustomer.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      notes: notes,
      tags: tags,
      metadata: metadata,
      active: active,
      updatedAt: DateTime.now(),
    );

    await _customerDatabase.updateCustomer(updatedCustomer);
    
    _logger.info(
      'Customer updated',
      data: {'customerId': id},
    );

    return updatedCustomer;
  }

  /// Delete a customer
  Future<void> deleteCustomer(String id) async {
    await _customerDatabase.deleteCustomer(id);
    
    _logger.info(
      'Customer deleted',
      data: {'customerId': id},
    );
  }

  /// Search customers by name or phone number
  Future<List<Customer>> searchCustomers(String query) async {
    return await _customerDatabase.searchCustomers(query);
  }

  /// Get scheduled SMS messages for a specific customer
  Future<List<ScheduledSMS>> getScheduledSmsForCustomer(String customerId) async {
    final allSms = await _database.getAllScheduledSms();
    return allSms.where((sms) => sms.customerId == customerId).toList();
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  final logger = SmsLogger();
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = SchedulerSmsService();
      await service.checkAndSendPendingSms();
      logger.logBackgroundTask(taskName: task, success: true, data: inputData);
      return true;
    } catch (e) {
      logger.logBackgroundTask(
        taskName: task,
        success: false,
        data: {
          'error': e.toString(),
        },
      );
      return false;
    }
  });
}
