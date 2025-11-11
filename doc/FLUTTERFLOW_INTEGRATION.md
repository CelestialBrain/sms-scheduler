# FlutterFlow Integration Guide

This guide provides step-by-step instructions for integrating the SchedulerSMS package into your FlutterFlow application, with a focus on per-customer scheduling and web support.

## 1. Adding the Package to FlutterFlow

1.  **Open your FlutterFlow project**.
2.  Navigate to **Settings & Integrations** → **Project Dependencies**.
3.  Click **Add Dependency**.
4.  Enter `schedulersms` and select version `^2.0.0`.
5.  Click **Add**.

FlutterFlow will automatically add the package to your `pubspec.yaml`.

> **Keeping the dependency fresh:** FlutterFlow caches package versions aggressively. After pushing updates to this repository,
> bump the `schedulersms` version in `pubspec.yaml` (for example from `2.0.0` to `2.0.1`) and then remove and re-add the
> dependency inside FlutterFlow. If you prefer to point to the Git repository directly, use the **Custom Pub Dependencies** tab
> and enter:
>
> ```text
> git:
>   url: https://github.com/Celestiariah/schedulersms.git
> ```
>
> Once the dependency is re-added, click **Refresh Packages** in FlutterFlow to ensure the latest commit is pulled.

## 2. Creating Custom Actions

FlutterFlow uses "Custom Actions" to execute Dart code. You will need to create custom actions for each operation you want to perform with the SchedulerSMS package.

### Custom Action: Initialize SchedulerSMS (Mobile)

**Action Name**: `initializeSchedulerSms`

**Return Type**: `Future<void>`

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<void> initializeSchedulerSms() async {
  final service = SchedulerSmsService();
  await service.initialize();
}
```

### Custom Action: Initialize SchedulerSMS (Web)

**Action Name**: `initializeSchedulerSmsWeb`

**Return Type**: `Future<void>`

**Code**:
```dart
import 'package:schedulersms/schedulersms_web.dart';
import 'package:http/http.dart' as http;

Future<void> initializeSchedulerSmsWeb() async {
  final smsSchedulerWeb = SchedulerSmsWeb();

  // Define your custom web SMS sender
  Future<bool> myWebSmsSender(ScheduledSMS sms) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend.com/api/send-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': sms.recipient,
          'message': sms.message,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  await smsSchedulerWeb.initialize(customSmsSender: myWebSmsSender);
}
```

### Custom Action: Create Customer

**Action Name**: `createCustomer`

**Parameters**:
- `name` (String)
- `phoneNumber` (String)
- `email` (String, optional)

**Return Type**: `Future<String>` (returns customer ID)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';
import 'package:uuid/uuid.dart';

Future<String> createCustomer(
  String name,
  String phoneNumber,
  String? email,
) async {
  final service = SchedulerSmsService();
  
  final customer = Customer(
    id: Uuid().v4(),
    name: name,
    phoneNumber: phoneNumber,
    email: email,
    createdAt: DateTime.now(),
  );
  
  await service.database.insertCustomer(customer);
  return customer.id;
}
```

### Custom Action: Schedule SMS for Customer

**Action Name**: `scheduleSmsForCustomer`

**Parameters**:
- `customerId` (String)
- `message` (String)
- `scheduledDate` (DateTime)

**Return Type**: `Future<String>` (returns SMS ID)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> scheduleSmsForCustomer(
  String customerId,
  String message,
  DateTime scheduledDate,
) async {
  final service = SchedulerSmsService();
  
  // Get customer from database
  final customer = await service.database.getCustomer(customerId);
  
  if (customer == null) {
    throw Exception('Customer not found');
  }
  
  final sms = await service.scheduleSms(
    customer: customer,
    message: message,
    scheduledDate: scheduledDate,
  );
  
  return sms.id;
}
```

### Custom Action: Get All Customers

**Action Name**: `getAllCustomers`

**Return Type**: `Future<List<dynamic>>` (returns list of customer maps)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<List<dynamic>> getAllCustomers() async {
  final service = SchedulerSmsService();
  final customers = await service.database.getAllCustomers();
  
  return customers.map((customer) => customer.toMap()).toList();
}
```

### Custom Action: Get Scheduled Messages for Customer

**Action Name**: `getScheduledMessagesForCustomer`

**Parameters**:
- `customerId` (String)

**Return Type**: `Future<List<dynamic>>` (returns list of SMS maps)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<List<dynamic>> getScheduledMessagesForCustomer(String customerId) async {
  final service = SchedulerSmsService();
  final messages = await service.getScheduledSmsForCustomer(customerId);
  
  return messages.map((sms) => sms.toMap()).toList();
}
```

## 3. Building the UI in FlutterFlow

### Customer List Screen

1.  **Create a new page** called `CustomerListPage`.
2.  **Add a ListView** to display customers.
3.  **Add a Custom Action** on page load to call `getAllCustomers()`.
4.  **Store the result** in a Page State variable (e.g., `customerList`).
5.  **Bind the ListView** to the `customerList` variable.
6.  **Add a FloatingActionButton** to navigate to a `CreateCustomerPage`.

### Create Customer Screen

1.  **Create a new page** called `CreateCustomerPage`.
2.  **Add TextFields** for `name`, `phoneNumber`, and `email`.
3.  **Add a Button** to submit the form.
4.  **On button tap**, call the `createCustomer()` custom action with the form values.
5.  **Navigate back** to the `CustomerListPage` after successful creation.

### Schedule SMS Screen

1.  **Create a new page** called `ScheduleSmsPage`.
2.  **Pass the `customerId`** as a parameter when navigating to this page.
3.  **Add a TextField** for the `message`.
4.  **Add a DateTimePicker** for the `scheduledDate`.
5.  **Add a Button** to submit the form.
6.  **On button tap**, call the `scheduleSmsForCustomer()` custom action.
7.  **Show a success message** and navigate back.

## 4. Web-Specific Considerations

When building for the web, you **must** ensure that:

1.  You call `initializeSchedulerSmsWeb()` instead of `initializeSchedulerSms()` on app startup.
2.  You have a backend API that can send SMS messages (e.g., using Twilio, Nexmo, etc.).
3.  Your `myWebSmsSender` function in the initialization code correctly calls your backend API.

## 5. Testing

-   **Mobile**: Test on a real Android device with SMS permissions granted.
-   **iOS**: Test on a real iOS device. Note that SMS will open the native composer.
-   **Web**: Test in a browser. Ensure your backend API is running and accessible.

By following this guide, you can fully integrate the SchedulerSMS package into your FlutterFlow application, enabling powerful per-customer SMS scheduling capabilities.
