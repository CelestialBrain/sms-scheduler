# FlutterFlow Integration Guide - Semaphore SMS API

This guide provides complete step-by-step instructions for integrating the SchedulerSMS package with Semaphore SMS API into your FlutterFlow application.

## Overview

The SchedulerSMS package now includes native support for **Semaphore SMS API**, a Philippine-based SMS service provider with affordable rates and reliable delivery. You can keep the Semaphore API key out of source control by passing it into the scheduler at runtime (for example, from a secure text field or app setting in FlutterFlow).

## Prerequisites

Before you begin, ensure you have:

1. A FlutterFlow account and project
2. Access to the `schedulersms` package from the GitHub repository
3. Your Semaphore API key (stored securely outside the repository)

## Step 1: Add the Package to FlutterFlow

### Option 1: Using Git Repository (Recommended)

1. Open your FlutterFlow project
2. Navigate to **Settings & Integrations** → **Project Dependencies**
3. Click **Add Dependency**
4. Select **Git** tab
5. Enter the following details:
   - **Git URL**: `https://github.com/CelestialBrain/schedulersms.git`
   - **Ref** (optional): Leave blank for latest, or specify a branch/tag
6. Click **Add**

### Option 2: Using Pub.dev (If Published)

1. Navigate to **Settings & Integrations** → **Project Dependencies**
2. Click **Add Dependency**
3. Search for `schedulersms`
4. Select version `^2.0.0` or later
5. Click **Add**

## Step 2: Create Custom Actions

FlutterFlow uses "Custom Actions" to execute Dart code. You'll need to create custom actions for each SchedulerSMS operation.

### 2.1. Initialize SchedulerSMS

**Action Name**: `initializeSchedulerSmsSemaphore`

**Parameters**: `apiKey` (String)

**Return Type**: `Future<String>`

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> initializeSchedulerSmsSemaphore(String apiKey) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.initialize(apiKey: apiKey);

    // Get account info to verify connection
    final account = await scheduler.getAccountInfo();

    return 'Initialized successfully! Balance: ${account.creditBalance} credits';
  } catch (e) {
    return 'Error: $e';
  }
}
```

**Usage**: Call this action when your app starts (e.g., in the initial page's "On Page Load" action). When you attach the action in FlutterFlow, bind the `apiKey` parameter to the text field, app state, or secure storage value where the user pasted their Semaphore key.

### 2.2. Create Customer

**Action Name**: `createCustomer`

**Parameters**:
- `name` (String) - Customer's full name
- `phoneNumber` (String) - Philippine mobile number (e.g., 09171234567)
- `email` (String, nullable) - Optional email address

**Return Type**: `Future<String>` (returns customer ID)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> createCustomer(
  String name,
  String phoneNumber,
  String? email,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    final customer = await scheduler.createCustomer(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );
    
    return customer.id;
  } catch (e) {
    throw Exception('Failed to create customer: $e');
  }
}
```

### 2.3. Schedule SMS for Customer

**Action Name**: `scheduleSmsForCustomer`

**Parameters**:
- `customerId` (String) - The ID of the customer
- `message` (String) - The message content
- `scheduledDate` (DateTime) - When to send the message

**Return Type**: `Future<String>` (returns SMS ID)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> scheduleSmsForCustomer(
  String customerId,
  String message,
  DateTime scheduledDate,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    // Get the customer
    final customer = await scheduler.getCustomer(customerId);
    
    if (customer == null) {
      throw Exception('Customer not found');
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

### 2.4. Schedule SMS Directly (Without Customer)

**Action Name**: `scheduleSmsDirectly`

**Parameters**:
- `phoneNumber` (String) - Philippine mobile number
- `message` (String) - The message content
- `scheduledDate` (DateTime) - When to send the message

**Return Type**: `Future<String>` (returns SMS ID)

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> scheduleSmsDirectly(
  String phoneNumber,
  String message,
  DateTime scheduledDate,
) async {
  try {
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
  } catch (e) {
    throw Exception('Failed to schedule SMS: $e');
  }
}
```

### 2.5. Get All Customers

**Action Name**: `getAllCustomers`

**Return Type**: `Future<List<dynamic>>`

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<List<dynamic>> getAllCustomers() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final customers = await scheduler.getAllCustomers();
    
    return customers.map((customer) => customer.toMap()).toList();
  } catch (e) {
    throw Exception('Failed to get customers: $e');
  }
}
```

### 2.6. Get Account Balance

**Action Name**: `getAccountBalance`

**Return Type**: `Future<double>`

**Code**:
```dart
import 'package:schedulersms/schedulersms.dart';

Future<double> getAccountBalance() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final account = await scheduler.getAccountInfo();
    
    return account.creditBalance;
  } catch (e) {
    throw Exception('Failed to get balance: $e');
  }
}
```

## Step 3: Build Your FlutterFlow UI

### 3.1. Simple SchedulerSMS Page

Create a simple page with three fields:

1. **TextField** - `recipientNumber` (Phone number)
2. **TextField** - `messageText` (Message content)
3. **DateTimePicker** - `scheduledDateTime` (When to send)
4. **Button** - "Schedule SMS"

**Button Action**:
1. Call `scheduleSmsDirectly` with the three field values
2. Show success message
3. Clear the form

### 3.2. Customer Management Page

**Customer List Page**:
1. Create a **ListView** widget
2. Add a **Custom Action** on page load: `getAllCustomers()`
3. Store result in **Page State** variable: `customerList`
4. Bind ListView to `customerList`
5. Add **FloatingActionButton** to navigate to "Create Customer" page

**Create Customer Page**:
1. Add **TextFields** for: `name`, `phoneNumber`, `email`
2. Add **Button** "Create Customer"
3. On button tap:
   - Call `createCustomer()` with field values
   - Navigate back to Customer List page

### 3.3. Account Balance Widget

Create a **Text** widget to display balance:

1. Add a **Custom Action** on page load: `getAccountBalance()`
2. Store result in **Page State** variable: `balance`
3. Display: "Balance: ${balance} credits"

## Step 4: Testing Your Integration

### Test Checklist

- [ ] App initializes successfully
- [ ] Can create customers
- [ ] Can view customer list
- [ ] Can schedule SMS with recipient, message, and date
- [ ] Can view scheduled messages
- [ ] Account balance displays correctly
- [ ] SMS sends at scheduled time (test with near-future time)

### Testing Tips

1. **Test with near-future times**: Schedule messages 2-3 minutes in the future to verify they send
2. **Check Philippine number format**: Use format `09171234567` (11 digits starting with 09)
3. **Monitor account balance**: Each SMS costs 1 credit (or 2 for priority)
4. **Check logs**: Use FlutterFlow's console to see any error messages

## Step 5: Phone Number Validation

Add this helper function to validate Philippine mobile numbers:

**Action Name**: `isValidPhilippineNumber`

**Parameters**: `phoneNumber` (String)

**Return Type**: `bool`

**Code**:
```dart
bool isValidPhilippineNumber(String phoneNumber) {
  // Remove all non-digit characters
  String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Handle +63 format
  if (cleaned.startsWith('63')) {
    cleaned = '0${cleaned.substring(2)}';
  } else if (cleaned.startsWith('9') && cleaned.length == 10) {
    cleaned = '0$cleaned';
  }
  
  // Should be 11 digits starting with 09
  if (cleaned.length != 11) return false;
  if (!cleaned.startsWith('09')) return false;
  
  return true;
}
```

## Important Notes

### API Key Security

Collect the Semaphore API key at runtime (for example, from the `apiKeyField` text field shown in the quick start) and pass it into `initializeSchedulerSmsSemaphore`. Avoid hardcoding the key in your repository or FlutterFlow project settings. If you need to persist the key between sessions, store it in FlutterFlow's secure storage or an encrypted backend endpoint.

### Message Costs

- **Regular SMS**: 1 credit per 160 characters
- **Priority SMS**: 2 credits per 160 characters (bypasses queue)
- **OTP SMS**: 2 credits per 160 characters (dedicated OTP route)

Messages longer than 160 characters are automatically split by Semaphore.

### Rate Limits

- **Send Messages**: 120 requests per minute
- **Get Messages**: 30 requests per minute
- **Account Info**: 2 requests per minute

### Philippine Number Format

Always use the format: `09XXXXXXXXX` (11 digits starting with 09)

Supported networks:
- **Globe**: 0905, 0906, 0915, 0916, 0917, 0926, 0927, 0935, 0936, 0945
- **Smart**: 0813, 0907-0910, 0912, 0918-0921, 0928-0930, 0938-0939, 0946-0951
- **DITO**: 0895-0898, 0991-0994

## Troubleshooting

### Issue: "Failed to initialize Semaphore API"

**Solution**: Check your internet connection and verify the API key text field or app state contains a valid Semaphore key before calling `initializeSchedulerSmsSemaphore`.

### Issue: "Invalid phone number"

**Solution**: Ensure the phone number is in the correct format (09XXXXXXXXX) and is a valid Philippine mobile number.

### Issue: "Insufficient credits"

**Solution**: Check your Semaphore account balance and top up if needed.

### Issue: Messages not sending

**Solution**: 
1. Verify the scheduled time is in the future
2. Check that the message is active (not disabled)
3. Review the message status in the database
4. Check the logs for error messages

## Complete Example: Simple SchedulerSMS App

Here's a complete example of a minimal SMS scheduler app:

### Page 1: Home Page

**Widgets**:
- Text: "SchedulerSMS"
- Text: "Balance: ${balance} credits"
- TextField: `phoneNumber`
- TextField: `message`
- DateTimePicker: `scheduledDate`
- Button: "Schedule SMS"

**Page State Variables**:
- `balance` (double)

**On Page Load**:
```dart
// Initialize scheduler
await initializeSchedulerSmsSemaphore();

// Get balance
balance = await getAccountBalance();
```

**Button Action**:
```dart
// Validate phone number
if (!isValidPhilippineNumber(phoneNumber)) {
  // Show error
  return;
}

// Schedule SMS
String smsId = await scheduleSmsDirectly(
  phoneNumber,
  message,
  scheduledDate,
);

// Show success message
// Clear form
```

## Next Steps

1. **Customize sender name**: Edit `SemaphoreConfig.defaultSenderName` in the package
2. **Enable priority queue**: Set `SemaphoreConfig.usePriorityQueue = true` for all messages
3. **Add message templates**: Create reusable message templates in your app
4. **Implement message history**: Show sent/failed messages to users
5. **Add notifications**: Notify users when messages are sent

## Support

For issues or questions:
- Check the package documentation
- Review the Semaphore API docs: https://www.semaphore.co/docs
- Check the GitHub repository issues

---

**Package Version**: 2.0.0+

**Last Updated**: November 6, 2025
