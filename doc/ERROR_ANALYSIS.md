# Error Analysis and Logging Guide

This guide provides detailed instructions on how to use the extensive logging features of the SchedulerSMS package to diagnose and resolve common issues.

## 1. Understanding the Logging System

The package includes a powerful `SmsLogger` that captures detailed information about every operation. The logger provides:

- **Log Levels**: `debug`, `info`, `warning`, `error`, `critical`
- **In-Memory History**: Access the last 1000 log entries.
- **Custom Handlers**: Send logs to your own analytics or monitoring service.
- **Pre-built Logging Functions**: For common events like scheduling, sending, and failures.

### Accessing the Logger

```dart
import 'package:schedulersms/src/utils/sms_logger.dart';

final logger = SmsLogger();
```

## 2. Common Errors and How to Diagnose Them

### Issue: SMS Not Sending on Android

**Symptoms**:
- Scheduled messages remain in `pending` status.
- No errors are thrown in the UI.

**Diagnosis Steps**:

1.  **Check for Error Logs**:

    ```dart
    final errorLogs = logger.getErrorLogs();
    for (final log in errorLogs) {
      print(log);
    }
    ```

2.  **Look for Common Error Messages**:

    -   `"Failed to send SMS: No permissions"`: The app does not have SMS permissions. Ensure you are requesting permissions at runtime.
    -   `"Failed to send SMS: Invalid number"`: The recipient's phone number is not valid.
    -   `"Background task failed"`: The background task is crashing. Check the device logs for more details.

3.  **Review Debug Logs**:

    ```dart
    final allLogs = logger.logHistory;
    print(allLogs.map((log) => log.toString()).join('\n'));
    ```

    Look for logs related to `logSendAttempt`, `logSendFailure`, and `logBackgroundTask`.

### Issue: Background Tasks Not Running

**Symptoms**:
- Messages are not sent when the app is in the background or closed.

**Diagnosis Steps**:

1.  **Check Battery Optimization Settings**: Many Android manufacturers have aggressive battery optimization that can kill background tasks. Advise users to disable battery optimization for your app.

2.  **Review Background Task Logs**:

    ```dart
    final backgroundLogs = logger.logHistory.where(
      (log) => log.message.contains('Background task'),
    );
    for (final log in backgroundLogs) {
      print(log);
    }
    ```

    Look for `"Background task failed"` logs.

3.  **Test with `adb`**: You can manually trigger the background task using `adb` to see if it runs correctly:

    ```bash
    adb shell cmd jobscheduler run -f <your_app_package_name> <job_id>
    ```

### Issue: SMS Not Working on Web

**Symptoms**:
- Messages are not being sent from your web app.
- You see the error `"No web SMS sender configured"` in the logs.

**Diagnosis Steps**:

1.  **Ensure `webSmsSender` is Provided**: You **must** provide a custom SMS sender function during initialization on the web.

    ```dart
    await smsSchedulerWeb.initialize(
      customSmsSender: myWebSmsSender,
    );
    ```

2.  **Check Your Backend API**: The `myWebSmsSender` function should call your backend API to send the SMS. Verify that:
    -   Your backend is running and accessible.
    -   The API endpoint is correct.
    -   Your backend is successfully calling the third-party SMS provider (e.g., Twilio).

3.  **Review Network Logs**: Use your browser's developer tools to inspect the network requests being made from your web app to your backend.

## 3. Advanced Logging

### Exporting Logs

You can export the entire log history as a JSON string, which can be saved to a file or sent to a server for analysis.

```dart
final jsonLogs = logger.exportLogsAsJson();
// Save to file or send to server
```

### Custom Log Handlers

For real-time error monitoring, you can add a custom log handler to send critical errors to a service like Sentry, Firebase Crashlytics, or your own logging backend.

```dart
logger.addLogHandler((entry) {
  if (entry.level == LogLevel.critical) {
    // Send to Sentry, etc.
    Sentry.captureException(
      entry.error,
      stackTrace: entry.stackTrace,
    );
  }
});
```

## 4. Log Analysis Best Practices

-   **Filter by Level**: Start by looking at `error` and `critical` logs to identify the most serious issues.
-   **Correlate by ID**: Use the `smsId` and `customerId` in the log data to trace the entire lifecycle of a message.
-   **Check Timestamps**: Use the timestamps to understand the sequence of events and identify delays or timeouts.
-   **Review Data Payloads**: The `data` field in each log entry contains valuable context about the operation.

By using these logging and error analysis techniques, you can quickly diagnose and resolve issues, ensuring a smooth and reliable experience for your users.
