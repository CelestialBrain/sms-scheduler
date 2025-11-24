import '../schedulersms_web_semaphore.dart';
import '../api/semaphore_api_client.dart';
import '../models/customer.dart';
import '../models/scheduled_sms.dart';

/// Testing utility for Semaphore SMS integration
///
/// This class provides opt-in testing methods for verifying Semaphore API
/// integration. It is designed for live testing and verification only.
///
/// **WARNING**: These methods will consume actual SMS credits when sending
/// messages to real phone numbers. Use with caution.
///
/// Example usage:
/// ```dart
/// final helper = SemaphoreTestHelper(apiKey: 'your-api-key');
/// await helper.initialize();
///
/// // Check account balance
/// final balance = await helper.getAccountBalance();
/// print('Balance: $balance credits');
///
/// // Send test SMS
/// final result = await helper.sendTestSms(
///   phoneNumber: '09171234567',
///   message: 'Test message',
/// );
/// print('SMS sent with ID: ${result.messageId}');
/// ```
class SemaphoreTestHelper {
  final String apiKey;
  final String senderName;
  late SchedulerSmsWebSemaphore _scheduler;
  late SemaphoreApiClient _apiClient;

  /// Create a new test helper with the given API key
  ///
  /// [apiKey] - Your Semaphore API key
  /// [senderName] - Optional sender name (defaults to 'SEMAPHORE')
  SemaphoreTestHelper({
    required this.apiKey,
    this.senderName = 'SEMAPHORE',
  });

  /// Initialize the test helper
  ///
  /// This must be called before using any other methods.
  /// It verifies the API key is valid by fetching account information.
  Future<void> initialize() async {
    _scheduler = SchedulerSmsWebSemaphore();
    await _scheduler.initialize(
      apiKey: apiKey,
      senderName: senderName,
    );
    _apiClient = SemaphoreApiClient(apiKey: apiKey);
  }

  /// Get account information including credit balance
  ///
  /// Returns a [SemaphoreAccount] object with account details.
  ///
  /// Example:
  /// ```dart
  /// final account = await helper.getAccountInfo();
  /// print('Account: ${account.accountName}');
  /// print('Balance: ${account.creditBalance} credits');
  /// print('Status: ${account.status}');
  /// ```
  Future<SemaphoreAccount> getAccountInfo() async {
    return await _scheduler.getAccountInfo();
  }

  /// Get the current credit balance
  ///
  /// Returns the credit balance as a double.
  ///
  /// Example:
  /// ```dart
  /// final balance = await helper.getAccountBalance();
  /// print('You have $balance credits remaining');
  /// ```
  Future<double> getAccountBalance() async {
    final account = await getAccountInfo();
    return account.creditBalance;
  }

  /// Send a test SMS immediately (not scheduled)
  ///
  /// **WARNING**: This will consume SMS credits and send a real message.
  ///
  /// [phoneNumber] - Recipient's phone number in Philippine format (09XXXXXXXXX)
  /// [message] - Message content to send
  /// [senderName] - Optional sender name override
  ///
  /// Returns a [TestSmsResult] with the message ID and status.
  ///
  /// Example:
  /// ```dart
  /// final result = await helper.sendTestSms(
  ///   phoneNumber: '09171234567',
  ///   message: 'Hello, this is a test message!',
  /// );
  /// print('Message sent! ID: ${result.messageId}, Status: ${result.status}');
  /// ```
  Future<TestSmsResult> sendTestSms({
    required String phoneNumber,
    required String message,
    String? senderName,
  }) async {
    final response = await _apiClient.sendMessage(
      number: phoneNumber,
      message: message,
      senderName: senderName ?? this.senderName,
    );

    return TestSmsResult(
      messageId: response.messageId.toString(),
      status: response.status,
      recipient: response.recipient,
      message: response.message,
      network: response.network,
      createdAt: response.createdAt,
    );
  }

  /// Schedule a test SMS for future delivery
  ///
  /// This creates a customer (if needed) and schedules an SMS through the
  /// scheduler system. The SMS will be sent at the specified time.
  ///
  /// [phoneNumber] - Recipient's phone number
  /// [message] - Message content
  /// [scheduledDate] - When to send the message
  /// [customerName] - Optional customer name (defaults to phone number)
  ///
  /// Returns a [ScheduledSMS] object with the scheduled message details.
  ///
  /// Example:
  /// ```dart
  /// final scheduled = await helper.scheduleTestSms(
  ///   phoneNumber: '09171234567',
  ///   message: 'This will arrive in 1 hour',
  ///   scheduledDate: DateTime.now().add(Duration(hours: 1)),
  /// );
  /// print('Scheduled with ID: ${scheduled.id}');
  /// ```
  Future<ScheduledSMS> scheduleTestSms({
    required String phoneNumber,
    required String message,
    required DateTime scheduledDate,
    String? customerName,
  }) async {
    // Find or create customer
    Customer? customer = await _scheduler.getCustomerByPhone(phoneNumber);
    if (customer == null) {
      customer = await _scheduler.createCustomer(
        name: customerName ?? 'Test Customer $phoneNumber',
        phoneNumber: phoneNumber,
      );
    }

    // Schedule the SMS
    return await _scheduler.scheduleSms(
      customer: customer,
      message: message,
      scheduledDate: scheduledDate,
    );
  }

  /// Dispose resources when done testing
  void dispose() {
    _scheduler.dispose();
    _apiClient.dispose();
  }
}

/// Result of a test SMS send operation
class TestSmsResult {
  /// Semaphore message ID
  final String messageId;

  /// Message status (e.g., 'Queued', 'Sent', 'Failed')
  final String status;

  /// Recipient phone number
  final String recipient;

  /// Message content
  final String message;

  /// Detected network (e.g., 'Globe', 'Smart', 'DITO')
  final String network;

  /// Timestamp when message was created
  final String createdAt;

  TestSmsResult({
    required this.messageId,
    required this.status,
    required this.recipient,
    required this.message,
    required this.network,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'TestSmsResult(messageId: $messageId, status: $status, '
        'recipient: $recipient, network: $network, createdAt: $createdAt)';
  }
}
