# Quick Start Guide - SchedulerSMS with Semaphore

Get your SMS scheduler up and running in FlutterFlow in **5 minutes**!

## Step 1: Add Package (1 minute)

1. Open your FlutterFlow project
2. Go to **Settings & Integrations** → **Project Dependencies**
3. Click **Add Dependency** → **Git** tab
4. Enter: `https://github.com/CelestialBrain/schedulersms.git`
5. Click **Add**

## Step 2: Create Initialize Action (1 minute)

1. Go to **Custom Code** → **Actions**
2. Click **+ Add Action**
3. Name: `initializeSchedulerSms`
4. Parameters: `apiKey` (String)
5. Return Type: `Future<String>`
6. Paste this code:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> initializeSchedulerSms(String apiKey) async {
  final scheduler = SchedulerSmsWebSemaphore();
  await scheduler.initialize(apiKey: apiKey);
  final account = await scheduler.getAccountInfo();
  return 'Balance: ${account.creditBalance} credits';
}
```

7. Click **Save**

## Step 3: Create Schedule SMS Action (1 minute)

1. Click **+ Add Action**
2. Name: `scheduleSms`
3. Parameters:
   - `phoneNumber` (String)
   - `message` (String)
   - `scheduledDate` (DateTime)
4. Return Type: `Future<String>`
5. Paste this code:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> scheduleSms(
  String phoneNumber,
  String message,
  DateTime scheduledDate,
) async {
  final scheduler = SchedulerSmsWebSemaphore();
  
  Customer? customer = await scheduler.getCustomerByPhone(phoneNumber);
  if (customer == null) {
    customer = await scheduler.createCustomer(
      name: 'Customer $phoneNumber',
      phoneNumber: phoneNumber,
    );
  }
  
  final sms = await scheduler.scheduleSms(
    customer: customer,
    message: message,
    scheduledDate: scheduledDate,
  );
  
  return 'SMS scheduled! ID: ${sms.id}';
}
```

6. Click **Save**

## Step 4: Build UI (2 minutes)

1. Create a new page called **SchedulerSMS**
2. Add these widgets:
   - **Column** (main container)
   - **Text**: "Semaphore API Key"
   - **TextField**: Name it `apiKeyField`, placeholder "Paste your Semaphore API key"
   - **Button**: Text "Connect"
   - **Divider**
   - **Text**: "Schedule SMS"
   - **TextField**: Name it `phoneField`, placeholder "09171234567"
   - **TextField**: Name it `messageField`, placeholder "Your message", multiline
   - **DateTimePicker**: Name it `dateTimePicker`
   - **Button**: Text "Schedule SMS"

3. Set up the **Connect** button action:
   - Add Action → **Custom Action**
   - Select `initializeSchedulerSms`
   - Map `apiKey` to `apiKeyField`'s text value
   - Add Action → **Show Snackbar**
   - Message: Action output (e.g., "Initialized successfully…")

4. Set up the **Schedule SMS** button action:
   - Add Action → **Custom Action**
   - Select `scheduleSms`
   - Map parameters:
     - `phoneNumber`: `phoneField` widget state
     - `message`: `messageField` widget state
     - `scheduledDate`: `dateTimePicker` widget state
   - Add Action → **Show Snackbar**
   - Message: Action output (the return value)

## Step 5: Test! (1 minute)

1. Click **Run** (or press F5)
2. Enter a Philippine mobile number (e.g., 09171234567)
3. Type a message
4. Select a date/time (a few minutes in the future for testing)
5. Click "Schedule SMS"
6. You should see "SMS scheduled! ID: ..."

**That's it!** Your SMS scheduler is now working! 🎉

## What's Next?

- **View scheduled messages**: Create a list view to show all scheduled SMS
- **Manage customers**: Add customer management pages
- **Check balance**: Display account balance on the page
- **Add validation**: Validate phone numbers before scheduling

## Full Documentation

For more advanced features, see:
- [Complete FlutterFlow Guide](doc/FLUTTERFLOW_SEMAPHORE_GUIDE.md)
- [All Custom Actions](example/flutterflow_custom_actions.dart)

## Troubleshooting

**"Package not found"**: Make sure you added the Git URL correctly

**"Failed to initialize"**: Check your internet connection

**"Invalid phone number"**: Use format 09XXXXXXXXX (11 digits)

**"Insufficient credits"**: Check your Semaphore account balance

## Need Help?

Check the [FlutterFlow Semaphore Guide](doc/FLUTTERFLOW_SEMAPHORE_GUIDE.md) for detailed instructions and troubleshooting.
