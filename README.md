# SMS Scheduler - Enhanced Edition

A powerful and flexible Flutter package for scheduling SMS messages, now with per-customer scheduling, web support, and extensive logging. Designed for seamless integration with FlutterFlow and custom Flutter applications.

## ✨ What's New

- **👥 Per-Customer Scheduling**: Associate scheduled messages with specific customers.
- **🌐 Web Support**: Web-compatible implementation for integration with backend SMS APIs (e.g., Twilio).
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
  sms_scheduler: ^2.0.0
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

No special configuration is needed for the web, but you must provide a custom SMS sender function during initialization.

## Usage

### 1. Initialization

**For Mobile:**
```dart
import 'package:sms_scheduler/sms_scheduler.dart';

final smsService = SmsSchedulerService();
await smsService.initialize();
```

**For Web:**
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
final customer = await smsService.createCustomer(
  name: 'John Doe',
  phoneNumber: '+639171234567',
);

// Get all customers
final customers = await smsService.getAllCustomers();

// Update a customer
await smsService.updateCustomer(
  id: customer.id,
  name: 'Johnathan Doe',
);
```

### 3. Per-Customer Scheduling

```dart
// Schedule an SMS for a specific customer
final scheduledSms = await smsService.scheduleSms(
  customer: customer,
  message: 'Hello, John! This is a scheduled message.',
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
);

// Get all messages for a customer
final customerMessages = await smsService.getScheduledSmsForCustomer(customer.id);
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

This package is fully compatible with FlutterFlow.

1.  **Add Package**: Add `sms_scheduler: ^2.0.0` to your `pubspec.yaml`.
2.  **Create Custom Actions**: Create custom actions for scheduling, customer management, etc.

**Example Custom Action for Per-Customer Scheduling:**
```dart
import 'package:sms_scheduler/sms_scheduler.dart';

Future<void> scheduleSmsForCustomer(
  String customerId,
  String message,
  DateTime scheduledDate,
) async {
  final service = SmsSchedulerService();
  await service.initialize();

  final customer = await service.getCustomer(customerId);
  if (customer != null) {
    await service.scheduleSms(
      customer: customer,
      message: message,
      scheduledDate: scheduledDate,
    );
  }
}
```

**Example Custom Action for Diagnostics:**
```dart
import 'package:sms_scheduler/sms_scheduler.dart';

Future<String> runDiagnosticsCustomAction() async {
  return runSmsSchedulerDiagnosticsAction();
}
```

`runSmsSchedulerDiagnosticsAction` prints a detailed diagnostics report to the
console and returns a short summary message that you can surface in FlutterFlow
UI elements. Call this from a button press to quickly verify scheduling
behaviour on both mobile and web builds.

## Limitations

-   **iOS**: Programmatic SMS sending is not possible. The native SMS composer will be opened.
-   **Web**: Direct SMS sending is not possible. Requires a backend and a custom SMS sender function.
-   **Background Execution**: Some Android devices may have aggressive battery optimization that can affect background tasks.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
