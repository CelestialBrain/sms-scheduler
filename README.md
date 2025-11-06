# SMS Scheduler - Enhanced Edition

A powerful and flexible Flutter package for scheduling SMS messages, now with per-customer scheduling, web support, Semaphore API integration, and extensive logging. Designed for seamless integration with FlutterFlow and custom Flutter applications.

## ✨ What's New

- **🔐 Secure API Key Management**: API keys are now passed as parameters instead of being hardcoded in the repository.
- **📱 Semaphore SMS Integration**: Built-in support for Semaphore SMS API (Philippine SMS provider).
- **👥 Per-Customer Scheduling**: Associate scheduled messages with specific customers.
- **🌐 Web Support**: Web-compatible implementation for integration with backend SMS APIs.
- **📝 Extensive Logging**: Comprehensive logging system for easy debugging and error analysis.
- **💪 Enhanced Models**: More detailed data models for `Customer` and `ScheduledSMS`.

## Features

- **📅 SMS Scheduling**: Schedule SMS messages for future dates and times.
- **🔄 Enable/Disable**: Toggle scheduled messages on/off.
- **👥 Customer Management**: Create, update, and manage customer profiles.
- **📱 Philippine Networks**: Full support for Globe, Smart, and DITO networks.
- **🌐 eSIM & Load APIs**: Clients for integrating with eSIM and load providers.
- **🔔 Status Updates**: Real-time status updates via streams.
- **💾 Local Storage**: Reliable message and customer storage with SQLite.
- **⚡ Background Processing**: Uses WorkManager for reliable background execution on mobile.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  sms_scheduler:
    git:
      url: https://github.com/CelestialBrain/sms-scheduler
      ref: main
```

Then run: `flutter pub get`

## Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSContactsUsageDescription</key>
<string>This app needs access to contacts to send SMS messages.</string>
```

**Note**: iOS does not allow sending SMS programmatically. The package will open the native SMS composer.

### Web

No special configuration is needed for the web. The package includes built-in support for Semaphore SMS API.

## Usage

### 1. Initialization

**For Mobile:**
```dart
import 'package:sms_scheduler/sms_scheduler.dart';

final smsService = SmsSchedulerService();
await smsService.initialize();
```

**For Web with Semaphore API:**
```dart
import 'package:sms_scheduler/sms_scheduler.dart';

final scheduler = SmsSchedulerWebSemaphore();

// Initialize with your Semaphore API key
await scheduler.initialize(
  apiKey: 'your-semaphore-api-key-here',
  senderName: 'YourBrand', // Optional, defaults to 'SEMAPHORE'
);
```

**For Web with Custom SMS Sender:**
```dart
import 'package:sms_scheduler/sms_scheduler_web.dart';

final smsSchedulerWeb = SmsSchedulerWeb();

// Define your custom web SMS sender
Future<bool> myWebSmsSender(ScheduledSMS sms) async {
  // Integrate with your backend API (e.g., Twilio)
  final response = await http.post(
    Uri.parse('https://your-backend.com/send-sms'),
    body: {
      'to': sms.recipient,
      'message': sms.message,
    },
  );
  return response.statusCode == 200;
}

await smsSchedulerWeb.initialize(customSmsSender: myWebSmsSender);
```

### 2. Managing Customers

```dart
// Create a customer
final customer = await scheduler.createCustomer(
  name: 'John Doe',
  phoneNumber: '09171234567',
);

// Get all customers
final customers = await scheduler.getAllCustomers();

// Update a customer
await scheduler.updateCustomer(
  id: customer.id,
  name: 'Johnathan Doe',
);
```

### 3. Per-Customer Scheduling

```dart
// Schedule an SMS for a specific customer
final scheduledSms = await scheduler.scheduleSms(
  customer: customer,
  message: 'Hello, John! This is a scheduled message.',
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
);

// Get all messages for a customer
final customerMessages = await scheduler.getScheduledSmsForCustomer(customer.id);
```

### 4. Extensive Logging

The package now includes a powerful logging system. You can access logs for debugging and error analysis.

```dart
import 'package:sms_scheduler/src/utils/sms_logger.dart';

final logger = SmsLogger();

// Get all log entries
final allLogs = logger.logHistory;

// Get only error logs
final errorLogs = logger.getErrorLogs();

// Export logs as JSON
final jsonLogs = logger.exportLogsAsJson();

// Add a custom log handler (e.g., to send logs to a server)
logger.addLogHandler((entry) {
  if (entry.level == LogLevel.error) {
    // Send error to your analytics service
  }
});
```

## Error Analysis Guide

For detailed instructions on how to use the logging system for troubleshooting, please see our [Error Analysis Guide](doc/ERROR_ANALYSIS.md).

## FlutterFlow Integration

This package is fully compatible with FlutterFlow. See the [example/flutterflow_custom_actions.dart](example/flutterflow_custom_actions.dart) file for ready-to-use custom actions.

### Quick Start for FlutterFlow

1.  **Add Package**: Go to Project Dependencies → Custom Pub Dependencies and add:
    ```
    sms-scheduler:
      git:
        url: https://github.com/CelestialBrain/sms-scheduler
        ref: main
    ```

2.  **Initialize on App Start**: Create a custom action with the following code:
    ```dart
    import 'package:sms_scheduler/sms_scheduler.dart';
    
    Future<String> initializeSmsScheduler(String apiKey) async {
      try {
        final scheduler = SmsSchedulerWebSemaphore();
        await scheduler.initialize(apiKey: apiKey);
        
        final account = await scheduler.getAccountInfo();
        return 'Initialized! Balance: ${account.creditBalance} credits';
      } catch (e) {
        return 'Error: $e';
      }
    }
    ```

3.  **Schedule SMS**: Create a custom action to schedule messages:
    ```dart
    import 'package:sms_scheduler/sms_scheduler.dart';
    
    Future<String> scheduleSms(
      String phoneNumber,
      String message,
      DateTime scheduledDate,
    ) async {
      try {
        final scheduler = SmsSchedulerWebSemaphore();
        
        // Create or find customer
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
      } catch (e) {
        throw Exception('Failed to schedule SMS: $e');
      }
    }
    ```

### Security Best Practices

**Important**: Never hardcode your API key in your public repository. Instead:

1. Store the API key in FlutterFlow's App State or Secure Storage
2. Pass the API key as a parameter when initializing the scheduler
3. For production apps, consider using environment variables or a secure backend to manage API keys

## Getting Your Semaphore API Key

1. Sign up at [https://semaphore.co/](https://semaphore.co/)
2. Navigate to your account dashboard
3. Copy your API key from the API section
4. Use this key when initializing the SMS scheduler

## Limitations

-   **iOS**: Programmatic SMS sending is not possible. The native SMS composer will be opened.
-   **Web**: Direct SMS sending is not possible. Requires a backend API or service like Semaphore.
-   **Background Execution**: Some Android devices may have aggressive battery optimization that can affect background tasks.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
