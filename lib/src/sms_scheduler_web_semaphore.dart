import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models/scheduled_sms.dart';
import 'models/sms_status.dart';
import 'models/customer.dart';
import 'database/sms_database.dart';
import 'utils/sms_logger.dart';
import 'api/semaphore_api_client.dart';
import 'database/customer_database.dart';
import 'config/semaphore_config.dart';

/// Web-compatible SMS scheduler service with Semaphore SMS API integration
/// 
/// This implementation uses the Semaphore SMS API to send messages from web applications.
/// The API key is configured in SemaphoreConfig for security.
class SmsSchedulerWebSemaphore {
  static final SmsSchedulerWebSemaphore _instance = SmsSchedulerWebSemaphore._internal();
  final SmsDatabase _database = SmsDatabase();
  final CustomerDatabase _customerDatabase = CustomerDatabase();
  final SmsLogger _logger = SmsLogger();
  final _uuid = const Uuid();
  late final SemaphoreApiClient _semaphoreClient;
  late String _senderName;
  late bool _usePriorityQueue;

  /// Stream controller for SMS status updates
  final _statusController = StreamController<ScheduledSMS>.broadcast();

  /// Timer for periodic checks
  Timer? _periodicTimer;

  factory SmsSchedulerWebSemaphore() => _instance;

  SmsSchedulerWebSemaphore._internal();

  /// Stream of SMS status updates
  Stream<ScheduledSMS> get statusStream => _statusController.stream;

  /// Initialize the web SMS scheduler with Semaphore API
  ///
  /// [apiKey] is required and should be provided by the user at runtime.
  /// This ensures the API key is not hardcoded in the repository.
  /// [senderName] overrides the default sender that will appear on outgoing
  /// messages.
  /// [usePriorityQueue] toggles Semaphore's priority queue for all messages
  /// (individual high-priority messages will still use the priority queue
  /// automatically).
  Future<void> initialize({
    required String apiKey,
    String? senderName,
    bool? usePriorityQueue,
  }) async {
    _logger.info('Initializing SMS Scheduler for Web with Semaphore API');

    // Initialize Semaphore client with API key
    _semaphoreClient = SemaphoreApiClient(apiKey: apiKey);
    _senderName = senderName ?? SemaphoreConfig.defaultSenderName;
    _usePriorityQueue = usePriorityQueue ?? SemaphoreConfig.usePriorityQueue;

    try {
      // Verify API key by getting account info
      final account = await _semaphoreClient.getAccount();
      _logger.info(
        'Semaphore API connected successfully',
        data: {
          'account': account.accountName,
          'balance': account.creditBalance,
          'status': account.status,
          'defaultSender': _senderName,
          'priorityQueue': _usePriorityQueue,
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to connect to Semaphore API',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to initialize Semaphore API: $e');
    }

    // Start periodic check for pending messages
    _startPeriodicCheck();
  }

  /// Start periodic check for pending SMS messages
  void _startPeriodicCheck() {
    // Check every minute for pending messages
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
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

    _logger.info('Periodic SMS check started (every 1 minute)');
  }

  /// Schedule a new SMS message
  Future<ScheduledSMS> scheduleSms({
    required Customer customer,
    required String message,
    required DateTime scheduledDate,
    bool active = true,
    List<String> tags = const [],
    int priority = 3,
    /// Optional sender name override for this scheduled SMS.
    String? senderName,
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
      senderName: senderName ?? _senderName,
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

  /// Send a single SMS message using Semaphore API
  Future<void> _sendSms(ScheduledSMS sms) async {
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

      // Send SMS using Semaphore API
      SemaphoreSmsResponse response;
      
      final resolvedSenderName = sms.senderName ?? _senderName;
      final usePriority = _usePriorityQueue || sms.priority >= 4;

      if (usePriority) {
        // Use priority queue for high-priority messages
        response = await _semaphoreClient.sendPriorityMessage(
          number: sms.recipient,
          message: sms.message,
          senderName: resolvedSenderName,
        );
      } else {
        // Use regular queue
        response = await _semaphoreClient.sendMessage(
          number: sms.recipient,
          message: sms.message,
          senderName: resolvedSenderName,
        );
      }

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

      _logger.info(
        'Semaphore API response',
        data: {
          'messageId': response.messageId,
          'network': response.network,
          'status': response.status,
          'senderName': resolvedSenderName,
          'priorityQueue': usePriority,
        },
      );
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
    String? senderName,
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
      senderName: senderName ?? existingSms.senderName,
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

  /// Get Semaphore account information
  Future<SemaphoreAccount> getAccountInfo() async {
    return await _semaphoreClient.getAccount();
  }

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

  /// Dispose resources
  void dispose() {
    _periodicTimer?.cancel();
    _statusController.close();
    _semaphoreClient.dispose();
  }
}
