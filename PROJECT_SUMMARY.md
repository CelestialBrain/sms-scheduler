# Flutter SchedulerSMS Package - Enhanced Edition

**Author**: beldan

**Date**: November 6, 2025

**Version**: 2.0.0 (Enhanced)

## Executive Summary

This document provides a comprehensive overview of the enhanced Flutter SchedulerSMS package, which now includes per-customer scheduling, extensive logging, web support, and improved documentation. The package has been redesigned based on best practices from established Flutter packages like `url_launcher` and `flutter_sms`.

## What's New in Version 2.0

### 1. Per-Customer Scheduling

The package now supports associating scheduled SMS messages with specific customers. This enables:

- **Customer Management**: Create, update, and manage customer profiles with detailed information (name, phone number, email, notes, tags, metadata).

- **Customer-Specific Messaging**: Schedule messages for individual customers rather than just phone numbers.

- **Message History**: Retrieve all scheduled messages for a specific customer.

- **Enhanced Tracking**: Better organization and reporting of SMS campaigns.

**Key Models**:

| Model | Description | Key Fields |
| --- | --- | --- |
| `Customer` | Represents a customer | `id`, `name`, `phoneNumber`, `email`, `notes`, `tags`, `metadata`, `active` |
| `ScheduledSMS` | Represents a scheduled message | `id`, `customerId`, `customerName`, `recipient`, `message`, `scheduledDate`, `active`, `status`, `retryCount`, `tags`, `priority` |

### 2. Extensive Logging System

A comprehensive logging system has been implemented to facilitate debugging and error analysis:

- **Multiple Log Levels**: `debug`, `info`, `warning`, `error`, `critical`

- **In-Memory History**: Stores the last 1000 log entries for review

- **Custom Log Handlers**: Allows integration with analytics services (Sentry, Firebase Crashlytics, etc.)

- **Pre-built Logging Functions**: Dedicated functions for common events (scheduling, sending, failures, cancellations)

- **Export Capabilities**: Export logs as JSON for analysis or storage

- **Filtering**: Filter logs by level, time range, or error status

**Key Features**:

```
final logger = SmsLogger();

// Access log history
final allLogs = logger.logHistory;
final errorLogs = logger.getErrorLogs();

// Export logs
final jsonLogs = logger.exportLogsAsJson();

// Add custom handler
logger.addLogHandler((entry) {
  if (entry.level == LogLevel.error) {
    // Send to analytics
  }
});
```

### 3. Web Support

The package now includes a web-compatible implementation (`SchedulerSmsWeb`):

- **Custom SMS Sender**: Allows integration with backend SMS APIs (Twilio, Nexmo, etc.)

- **Periodic Checks**: Automatically checks for pending messages at regular intervals

- **Same API**: Maintains a consistent API with the mobile implementation

- **Flexible Integration**: Works with any backend SMS provider

**Web Implementation Example**:

```
final smsSchedulerWeb = SchedulerSmsWeb();

Future<bool> myWebSmsSender(ScheduledSMS sms) async {
  final response = await http.post(
    Uri.parse('https://your-backend.com/send-sms'),
    body: {'to': sms.recipient, 'message': sms.message},
  );
  return response.statusCode == 200;
}

await smsSchedulerWeb.initialize(customSmsSender: myWebSmsSender);
```

### 4. Enhanced Documentation

The package now includes comprehensive documentation:

- **README.md**: Updated with new features and usage examples

- **ERROR_ANALYSIS.md**: Detailed guide for diagnosing and resolving common issues

- **FLUTTERFLOW_INTEGRATION.md**: Step-by-step guide for FlutterFlow integration

- **Code Comments**: Extensive inline documentation throughout the codebase

## Package Structure

The enhanced package follows a clean, modular structure inspired by `url_launcher` and `flutter_sms`:

```
lib/
├── src/
│   ├── api/                          # API clients for eSIM and load
│   │   ├── esim_api_client.dart
│   │   └── load_api_client.dart
│   ├── database/                     # SQLite database handlers
│   │   ├── sms_database.dart
│   │   └── customer_database.dart (new)
│   ├── models/                       # Data models
│   │   ├── customer.dart (new)
│   │   ├── scheduled_sms.dart (enhanced)
│   │   └── sms_status.dart
│   ├── utils/                        # Utilities
│   │   ├── sms_logger.dart (new)
│   │   └── sms_validator.dart
│   ├── schedulersms_service.dart    # Main mobile service
│   └── schedulersms_web.dart (new)  # Web implementation
├── schedulersms.dart                # Main export file
└── schedulersms_web.dart (new)      # Web export file
```

## Best Practices Applied

Based on the analysis of `url_launcher` and `flutter_sms`, the following best practices have been applied:

1. **Clean Export Structure**: Main library files only export modules, keeping the public API clean.

1. **Platform Abstraction**: Separate implementations for mobile and web platforms.

1. **Modular Design**: Clear separation of concerns (models, database, API, utilities).

1. **Type Safety**: Extensive use of enums and typed parameters.

1. **Error Handling**: Comprehensive error handling with detailed error messages.

1. **Documentation**: Extensive inline documentation and separate guides.

1. **Web Compatibility**: Dedicated web implementation with clear integration points.

## Key Use Cases

### Use Case 1: Per-Customer SMS Campaigns

A business wants to send personalized SMS messages to each customer on their birthday.

```
// Create customers
for (final customerData in customerList) {
  final customer = await smsService.createCustomer(
    name: customerData['name'],
    phoneNumber: customerData['phone'],
    metadata: {'birthday': customerData['birthday']},
  );
  
  // Schedule birthday message
  await smsService.scheduleSms(
    customer: customer,
    message: 'Happy Birthday, ${customer.name}!',
    scheduledDate: DateTime.parse(customer.metadata['birthday']!),
    tags: ['birthday', 'campaign'],
  );
}
```

### Use Case 2: Web-Based SchedulerSMS

A web application needs to schedule SMS messages using a backend API.

```
// Initialize with custom sender
await smsSchedulerWeb.initialize(
  customSmsSender: (sms) async {
    return await twilioApi.sendSms(sms.recipient, sms.message);
  },
);

// Schedule message
await smsSchedulerWeb.scheduleSms(
  customer: customer,
  message: 'Your appointment is tomorrow at 3 PM',
  scheduledDate: DateTime.now().add(Duration(hours: 24)),
);
```

### Use Case 3: Error Monitoring and Debugging

A developer wants to monitor SMS sending failures and send alerts.

```
final logger = SmsLogger();

// Add custom handler for critical errors
logger.addLogHandler((entry) {
  if (entry.level == LogLevel.critical) {
    // Send alert to Slack or email
    alertService.sendAlert(
      'Critical SMS Error',
      entry.message,
      entry.data,
    );
  }
});

// Get error logs for analysis
final errorLogs = logger.getErrorLogs();
for (final log in errorLogs) {
  print('Error: ${log.message}');
  print('Data: ${log.data}');
  print('Stack Trace: ${log.stackTrace}');
}
```

## FlutterFlow Integration

The package is fully compatible with FlutterFlow through custom actions. Key custom actions include:

- `initializeSchedulerSms()`: Initialize the service

- `createCustomer()`: Create a new customer

- `scheduleSmsForCustomer()`: Schedule an SMS for a customer

- `getAllCustomers()`: Retrieve all customers

- `getScheduledMessagesForCustomer()`: Get messages for a specific customer

See the [FlutterFlow Integration Guide](doc/FLUTTERFLOW_INTEGRATION.md) for detailed instructions.

## Philippine eSIM and Load API Integration

The package continues to support integration with eSIM and load providers:

### eSIM Providers (with APIs)

| Provider | API Available | Philippine Networks | Documentation |
| --- | --- | --- | --- |
| **Airalo** | ✅ Yes | Globe, Smart | [partners-doc.airalo.com](https://partners-doc.airalo.com/) |
| **eSIM Access** | ✅ Yes | Multiple | [docs.esimaccess.com](https://docs.esimaccess.com/) |
| **eSIM Go** | ✅ Yes | Multiple | [docs.esim-go.com](https://docs.esim-go.com/) |
| **Telnyx** | ✅ Yes | Global | [telnyx.com/products/esim](https://telnyx.com/products/esim) |

### Load Reseller APIs

| Provider | Contact | Notes |
| --- | --- | --- |
| **Loademy** | [admin@loademy.net](mailto:admin@loademy.net) | API and bulk eloading solutions |
| **PrepayNation** | [prepaynation.com](https://prepaynation.com/) | Digital prepaid marketplace |

## Error Analysis and Troubleshooting

The enhanced logging system makes it easy to diagnose and resolve issues. Common problems and their solutions:

### Problem: SMS Not Sending on Android

**Diagnosis**:

```
final errorLogs = logger.getErrorLogs();
// Look for "Failed to send SMS" messages
```

**Common Causes**:

- Missing SMS permissions

- Invalid phone number format

- Background task killed by battery optimization

**Solution**: Check permissions, validate phone numbers, advise users to disable battery optimization.

### Problem: Background Tasks Not Running

**Diagnosis**:

```
final backgroundLogs = logger.logHistory.where(
  (log) => log.message.contains('Background task'),
);
```

**Common Causes**:

- Aggressive battery optimization

- WorkManager not properly initialized

**Solution**: Test with `adb`, ensure WorkManager is initialized, advise users on battery settings.

### Problem: Web SMS Not Working

**Diagnosis**:

```
// Check for "No web SMS sender configured" error
```

**Common Causes**:

- No custom SMS sender provided during initialization

- Backend API not accessible

**Solution**: Provide a `customSmsSender` function, verify backend API is running.

See the [Error Analysis Guide](doc/ERROR_ANALYSIS.md) for more details.

## Getting Started

### Quick Start (5 minutes)

1. **Install the package**:

1. **Add permissions** (Android):

1. **Initialize and schedule**:

## Conclusion

The enhanced SchedulerSMS package provides a powerful, flexible, and well-documented solution for scheduling SMS messages in Flutter applications. With per-customer scheduling, extensive logging, web support, and comprehensive documentation, it is ready for production use in both mobile and web applications, including seamless integration with FlutterFlow.

For questions or support, please refer to the documentation included in this package or open an issue on GitHub.

---

**Package Version**: 2.0.0 (Enhanced Edition)

**License**: MIT

**Maintainer**: beldan

