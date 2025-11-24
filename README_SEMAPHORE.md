# SchedulerSMS - Semaphore Edition

A powerful and flexible Flutter package for scheduling SMS messages with **native Semaphore SMS API integration**. Designed for seamless integration with FlutterFlow and custom Flutter applications, with a focus on Philippine SMS delivery.

## ✨ What's New - Semaphore Integration

- **🇵🇭 Semaphore SMS API**: Native integration with Semaphore, a Philippine-based SMS provider
- **💰 Affordable Rates**: Cost-effective SMS delivery for Philippine mobile networks
- **🔐 Secure API Key**: API key stored securely in private repository
- **🚀 Ready to Use**: Pre-configured and ready for FlutterFlow integration
- **📊 Account Management**: Built-in balance checking and account info retrieval
- **⚡ Priority Queue**: Support for time-sensitive messages

## Features

- **📅 SMS Scheduling**: Schedule SMS messages for future dates and times
- **🔄 Enable/Disable**: Toggle scheduled messages on/off
- **👥 Customer Management**: Create, update, and manage customer profiles
- **📱 Philippine Networks**: Full support for Globe, Smart, and DITO networks
- **🌐 Web Support**: Works perfectly in FlutterFlow web applications
- **🔔 Status Updates**: Real-time status updates via streams
- **💾 Local Storage**: Reliable message and customer storage
- **📝 Extensive Logging**: Comprehensive logging system for debugging

## Quick Start

### 1. Add to FlutterFlow

Add this package to your FlutterFlow project:

**Git Repository**:
```
https://github.com/CelestialBrain/schedulersms.git
```

Or add to `pubspec.yaml`:
```yaml
dependencies:
  schedulersms:
    git:
      url: https://github.com/CelestialBrain/schedulersms.git
```

### 2. Initialize in FlutterFlow

Create a custom action called `initializeSchedulerSms`:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> initializeSchedulerSms() async {
  final scheduler = SchedulerSmsWebSemaphore();
  await scheduler.initialize();
  
  final account = await scheduler.getAccountInfo();
  return 'Balance: ${account.creditBalance} credits';
}
```

Call this action when your app starts.

### 3. Schedule Your First SMS

Create a custom action to schedule an SMS:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> scheduleSms(
  String phoneNumber,
  String message,
  DateTime scheduledDate,
) async {
  final scheduler = SchedulerSmsWebSemaphore();
  
  // Find or create customer
  Customer? customer = await scheduler.getCustomerByPhone(phoneNumber);
  if (customer == null) {
    customer = await scheduler.createCustomer(
      name: 'Customer $phoneNumber',
      phoneNumber: phoneNumber,
    );
  }
  
  // Schedule the SMS
  final sms = await scheduler.scheduleSms(
    customer: customer,
    message: message,
    scheduledDate: scheduledDate,
  );
  
  return sms.id;
}
```

### 4. Build Your UI

In FlutterFlow, create a simple form:
- **TextField**: Phone number (e.g., 09171234567)
- **TextField**: Message content
- **DateTimePicker**: Scheduled date/time
- **Button**: "Schedule SMS"

On button tap, call your `scheduleSms` custom action with the form values.

## Phone Number Format

Use Philippine mobile number format: `09XXXXXXXXX` (11 digits starting with 09)

**Supported Networks**:
- **Globe**: 0905, 0906, 0915, 0916, 0917, 0926, 0927, 0935, 0936, 0945
- **Smart**: 0813, 0907-0910, 0912, 0918-0921, 0928-0930, 0938-0939, 0946-0951
- **DITO**: 0895-0898, 0991-0994

## Pricing

- **Regular SMS**: 1 credit per 160 characters
- **Priority SMS**: 2 credits per 160 characters (bypasses queue)
- **OTP SMS**: 2 credits per 160 characters (dedicated OTP route)

Messages longer than 160 characters are automatically split by Semaphore.

## API Key Configuration

The Semaphore API key is pre-configured in the package at:
```
lib/src/config/semaphore_config.dart
```

Since this repository is **private**, your API key is secure and won't be exposed publicly.

**Current API Key**: `1fd72138299086e8fc5656a9826ac7e9`

## Complete FlutterFlow Integration Guide

For detailed step-by-step instructions, see:
- [FlutterFlow Semaphore Guide](doc/FLUTTERFLOW_SEMAPHORE_GUIDE.md)
- [Example Custom Actions](example/flutterflow_custom_actions.dart)

## Core Custom Actions for FlutterFlow

Here are the essential custom actions you'll need:

### Initialize
```dart
Future<String> initializeSchedulerSmsSemaphore()
```

### Customer Management
```dart
Future<String> createCustomer(String name, String phoneNumber, String? email)
Future<List<dynamic>> getAllCustomers()
Future<void> updateCustomer(String customerId, String? name, String? phoneNumber, String? email)
Future<void> deleteCustomer(String customerId)
```

### SMS Scheduling
```dart
Future<String> scheduleSmsForCustomer(String customerId, String message, DateTime scheduledDate)
Future<String> scheduleSmsDirectly(String phoneNumber, String message, DateTime scheduledDate)
Future<List<dynamic>> getAllScheduledMessages()
Future<void> cancelScheduledSms(String smsId)
```

### Account Info
```dart
Future<double> getAccountBalance()
Future<dynamic> getSemaphoreAccountInfo()
```

## Example Usage

### Schedule a Birthday Greeting

```dart
// Create customer
final customerId = await createCustomer(
  'Juan Dela Cruz',
  '09171234567',
  'juan@email.com',
);

// Schedule birthday message
final smsId = await scheduleSmsForCustomer(
  customerId,
  'Happy Birthday, Juan! 🎉',
  DateTime(2025, 12, 25, 9, 0), // Dec 25, 2025 at 9:00 AM
);
```

### Send Appointment Reminder

```dart
final smsId = await scheduleSmsDirectly(
  '09171234567',
  'Reminder: Your appointment is tomorrow at 3:00 PM.',
  DateTime.now().add(Duration(hours: 24)),
);
```

### Check Account Balance

```dart
final balance = await getAccountBalance();
print('Remaining credits: $balance');
```

## Architecture

The package uses a clean, modular architecture:

```
lib/
├── src/
│   ├── api/
│   │   └── semaphore_api_client.dart     # Semaphore API integration
│   ├── config/
│   │   └── semaphore_config.dart         # API key configuration
│   ├── database/
│   │   ├── sms_database.dart             # SMS message storage
│   │   └── customer_database.dart        # Customer data storage
│   ├── models/
│   │   ├── customer.dart                 # Customer model
│   │   ├── scheduled_sms.dart            # SMS model
│   │   └── sms_status.dart               # Status enum
│   ├── utils/
│   │   ├── sms_logger.dart               # Logging system
│   │   └── sms_validator.dart            # Phone number validation
│   └── schedulersms_web_semaphore.dart  # Main service
└── schedulersms.dart                     # Package exports
```

## Logging and Debugging

The package includes comprehensive logging:

```dart
import 'package:schedulersms/schedulersms.dart';

final logger = SmsLogger();

// Get all logs
final allLogs = logger.logHistory;

// Get only errors
final errorLogs = logger.getErrorLogs();

// Export logs as JSON
final jsonLogs = logger.exportLogsAsJson();
```

## Rate Limits

Semaphore API has the following rate limits:
- **Send Messages**: 120 requests per minute
- **Get Messages**: 30 requests per minute
- **Account Info**: 2 requests per minute

The package automatically handles these limits.

## Web Storage

For web applications, the package uses in-memory storage. Messages are stored temporarily and will be lost on page refresh. For production use, consider implementing persistent storage using IndexedDB or localStorage.

## Troubleshooting

### Messages Not Sending

1. Check scheduled time is in the future
2. Verify phone number format (09XXXXXXXXX)
3. Ensure sufficient account balance
4. Check message status in logs

### Invalid Phone Number

Use the format validator:

```dart
bool isValid = isValidPhilippineNumber('09171234567');
```

### API Connection Failed

1. Check internet connection
2. Verify API key in `semaphore_config.dart`
3. Check Semaphore service status

## Live API Testing

The package includes dedicated testing utilities for verifying your Semaphore integration end-to-end.

### Running the Live Test Script

A ready-to-use test script is provided at `example/semaphore_live_test.dart`:

```bash
# Check account balance only
dart run example/semaphore_live_test.dart

# Send a test SMS to verify delivery
dart run example/semaphore_live_test.dart 09171234567
```

**What it does:**
- Connects to the Semaphore API with your API key
- Displays your account information and credit balance
- Optionally sends a test SMS to verify end-to-end functionality

**API Key Configuration:**
- By default, uses the test API key `1fd72138299086e8fc5656a9826ac7e9`
- Override with environment variable: `SEMAPHORE_API_KEY=your-key dart run example/semaphore_live_test.dart`

**⚠️ WARNING**: This will call the real Semaphore API and consume credits when sending SMS.

### Using Testing Utilities in Your Code

For programmatic testing, use the `SemaphoreTestHelper` class:

```dart
import 'package:schedulersms/schedulersms.dart';

// Initialize with your API key
final helper = SemaphoreTestHelper(
  apiKey: 'your-api-key-here', // Replace with your actual key
);
await helper.initialize();

// Check account balance
final balance = await helper.getAccountBalance();
print('Balance: $balance credits');

// Get full account info
final account = await helper.getAccountInfo();
print('Account: ${account.accountName}');
print('Status: ${account.status}');

// Send a test SMS immediately
final result = await helper.sendTestSms(
  phoneNumber: '09171234567',
  message: 'Test message from SchedulerSMS',
);
print('SMS sent! ID: ${result.messageId}, Status: ${result.status}');

// Don't forget to dispose when done
helper.dispose();
```

**Security Note**: The testing utilities are designed for development and verification only. Never commit API keys to public repositories. Use environment variables or secure storage for production applications.

### FlutterFlow Testing

To test from FlutterFlow, create a custom action:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> testSemaphoreConnection(String apiKey) async {
  final helper = SemaphoreTestHelper(apiKey: apiKey);
  
  try {
    await helper.initialize();
    final balance = await helper.getAccountBalance();
    helper.dispose();
    return 'Connected! Balance: $balance credits';
  } catch (e) {
    return 'Error: $e';
  }
}
```

## Documentation

- [FlutterFlow Semaphore Guide](doc/FLUTTERFLOW_SEMAPHORE_GUIDE.md) - Complete integration guide
- [Example Custom Actions](example/flutterflow_custom_actions.dart) - Ready-to-use code
- [Live Test Script](example/semaphore_live_test.dart) - API verification tool
- [Error Analysis Guide](doc/ERROR_ANALYSIS.md) - Debugging help
- [Semaphore API Docs](https://www.semaphore.co/docs) - Official API documentation

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Credits

- **SMS Provider**: [Semaphore](https://www.semaphore.co/)
- **Package Author**: beldan
- **Version**: 2.0.0+

---

**Ready to send your first SMS?** Follow the [FlutterFlow Semaphore Guide](doc/FLUTTERFLOW_SEMAPHORE_GUIDE.md) to get started! 🚀
