# FlutterFlow Integration Guide for SchedulerSMS Dependency

## Test Results Summary

**Date**: November 11, 2025  
**Status**: ✅ ALL TESTS PASSED  
**API Provider**: Semaphore SMS API  
**Account**: YOUR_CLINIC_NAME  
**Balance**: 1010 credits  

---

## Testing Environment Results

### ✅ Test 1: Account Connection
- **Status**: PASSED
- **Account ID**: XXXXX
- **Account Name**: YOUR_CLINIC_NAME
- **Credit Balance**: 1010 credits
- **Account Status**: Active

### ✅ Test 2: Sender Names
- **Status**: PASSED
- **Available Sender**: SEMAPHORE (default)
- **Note**: Custom sender names need to be registered with Semaphore

### ✅ Test 3: Phone Number Validation
- **Status**: PASSED
- **Test Phone**: 09XXXXXXXXX
- **Format**: Valid Philippine mobile number (11 digits, starts with 09)
- **Network**: Smart

### ✅ Test 4: Basic Message Sending
- **Status**: PASSED
- **Message ID**: 258598834
- **Delivery Status**: Pending (queued for delivery)
- **Network**: Smart
- **Cost**: 1 credit

### ✅ Test 5: Dental Appointment Reminder
- **Status**: PASSED
- **Message ID**: 258598855
- **Delivery Status**: Pending (queued for delivery)
- **Message Length**: 219 characters (2 SMS parts)
- **Cost**: 2 credits

### ✅ Test 6: FlutterFlow Parameters
- **Status**: PASSED
- All required parameters documented

---

## What Environment is Good for Testing?

Based on the testing completed, here are the recommended environments:

### 1. **Python Testing Environment (Recommended for API Testing)**
✅ **Best for**: Quick API validation and debugging
- Direct HTTP requests to Semaphore API
- Fast iteration and testing
- Easy to debug and log responses
- No Flutter/Dart setup required

**Setup**:
```bash
pip3 install requests
python3 test_complete.py
```

### 2. **Flutter Web Test Project (Recommended for Full Integration)**
✅ **Best for**: Testing the actual Dart package before FlutterFlow
- Tests the actual package code
- Validates database operations
- Tests scheduling logic
- Simulates FlutterFlow environment

**Setup**:
```bash
flutter create test_schedulersms
cd test_schedulersms
# Add dependency to pubspec.yaml
flutter pub get
flutter run -d chrome
```

### 3. **FlutterFlow Sandbox Project (Recommended for Final Testing)**
✅ **Best for**: Testing custom actions in actual FlutterFlow
- Real FlutterFlow environment
- Tests custom actions
- Validates UI integration
- End-to-end testing

---

## Required Parameters for FlutterFlow Sandbox Project

### 1. **Initialization Parameters** (App Start)

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `apiKey` | String | ✅ Yes | Your Semaphore API key | `YOUR_SEMAPHORE_API_KEY` |
| `senderName` | String | ❌ No | Custom sender name (must be registered) | `SEMAPHORE` (default) |
| `usePriorityQueue` | bool | ❌ No | Use priority queue for all messages | `false` |

### 2. **Customer Management Parameters**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `customerName` | String | ✅ Yes | Patient/customer full name | `John Doe` |
| `customerPhone` | String | ✅ Yes | Philippine mobile number | `09XXXXXXXXX` |
| `customerEmail` | String | ❌ No | Email address | `john@example.com` |
| `customerNotes` | String | ❌ No | Additional notes | `Regular patient` |

### 3. **Appointment Scheduling Parameters**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `appointmentDate` | DateTime | ✅ Yes | When appointment occurred | `2025-11-08 10:00:00` |
| `daysAfterAppointment` | int | ✅ Yes | Days to wait before sending | `3` |
| `messageTemplate` | String | ✅ Yes | Message content | See template below |

### 4. **Message Customization Parameters**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `clinicName` | String | ✅ Yes | Your clinic/business name | `VBE Eye Center` |
| `doctorName` | String | ❌ No | Doctor's name | `Dr. Smith` |
| `followUpInstructions` | String | ❌ No | Care instructions | `Take medication twice daily` |
| `priority` | int | ❌ No | Message priority (1-5) | `3` (default) |

---

## Message Template Example

### For Dental Appointments:
```dart
String messageTemplate = "Hi {customerName}, thank you for visiting {clinicName}! "
    "We hope your appointment on {appointmentDate} went well. "
    "Please remember to {followUpInstructions}. "
    "If you have any concerns, feel free to contact us!";
```

### Variables to Replace:
- `{customerName}` → Patient name
- `{clinicName}` → Your clinic name
- `{appointmentDate}` → Formatted appointment date
- `{followUpInstructions}` → Post-appointment care instructions

### Example Output:
```
Hi John Doe, thank you for visiting VBE Eye Center! We hope your appointment on November 08 went well. Please remember to brush twice daily and floss regularly. If you have any concerns, feel free to contact us!
```

---

## FlutterFlow Custom Actions Required

### 1. **Initialize SchedulerSMS** (On App Start)

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> initializeSchedulerSms(String apiKey) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.initialize(apiKey: apiKey);
    
    final account = await scheduler.getAccountInfo();
    return 'Initialized! Balance: ${account.creditBalance} credits';
  } catch (e) {
    return 'Error: $e';
  }
}
```

### 2. **Schedule Appointment Reminder**

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> scheduleAppointmentReminder(
  String patientName,
  String patientPhone,
  DateTime appointmentDate,
  int daysAfter,
  String clinicName,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    // Find or create customer
    Customer? customer = await scheduler.getCustomerByPhone(patientPhone);
    if (customer == null) {
      customer = await scheduler.createCustomer(
        name: patientName,
        phoneNumber: patientPhone,
      );
    }
    
    // Calculate scheduled date
    final scheduledDate = appointmentDate.add(Duration(days: daysAfter));
    
    // Create message
    final message = "Hi $patientName, thank you for visiting $clinicName! "
        "We hope your appointment on ${appointmentDate.month}/${appointmentDate.day} went well. "
        "Please remember to follow the post-appointment care instructions. "
        "If you have any concerns, feel free to contact us!";
    
    // Schedule SMS
    final sms = await scheduler.scheduleSms(
      customer: customer,
      message: message,
      scheduledDate: scheduledDate,
    );
    
    return sms.id;
  } catch (e) {
    throw Exception('Failed to schedule reminder: $e');
  }
}
```

### 3. **Get Account Balance**

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

### 4. **Get All Scheduled Messages**

```dart
import 'package:schedulersms/schedulersms.dart';

Future<List<dynamic>> getAllScheduledMessages() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final messages = await scheduler.getAllScheduledSms();
    return messages.map((msg) => msg.toMap()).toList();
  } catch (e) {
    throw Exception('Failed to get messages: $e');
  }
}
```

---

## Testing Workflow for FlutterFlow

### Step 1: Add Package Dependency
1. Go to **Settings & Integrations** → **Project Dependencies**
2. Click **Add Dependency** → **Git** tab
3. Enter Git URL: `https://github.com/CelestialBrain/schedulersms.git`
4. Click **Add**

### Step 2: Create Custom Actions
1. Create each custom action listed above
2. Set correct parameter types and return types
3. Import the package: `import 'package:schedulersms/schedulersms.dart';`

### Step 3: Create Test UI
1. **Home Page**:
   - TextField: API Key input
   - Button: "Initialize" (calls `initializeSchedulerSms`)
   - Text: Display balance

2. **Schedule Reminder Page**:
   - TextField: Patient Name
   - TextField: Patient Phone
   - DateTimePicker: Appointment Date
   - TextField: Days After (number)
   - TextField: Clinic Name
   - Button: "Schedule Reminder"

### Step 4: Test Flow
1. ✅ Initialize with API key
2. ✅ Check balance displays correctly
3. ✅ Schedule a test reminder (use 1 minute in future for testing)
4. ✅ Verify message sends
5. ✅ Check SMS received on phone

---

## Important Notes

### 1. **Sender Name Registration**
- Default sender is "SEMAPHORE"
- Custom sender names must be registered with Semaphore
- Registration process: Contact Semaphore support
- Cost: May require additional fees

### 2. **Message Costs**
- Regular SMS: **1 credit** per 160 characters
- Priority SMS: **2 credits** per 160 characters
- Messages are automatically split if > 160 characters

### 3. **Phone Number Format**
- Must be Philippine mobile number
- Format: `09XXXXXXXXX` (11 digits)
- Supported networks: Globe, Smart, DITO
- Validation is built into the package

### 4. **Scheduling Logic**
- Messages are checked every 1 minute
- Scheduled messages are stored in local database
- Messages send automatically when due
- Failed messages can be retried

### 5. **API Rate Limits**
- Send Messages: 120 requests/minute
- Get Messages: 30 requests/minute
- Account Info: 2 requests/minute

### 6. **Security Best Practices**
- ⚠️ **NEVER** hardcode API key in repository
- ✅ Store API key in FlutterFlow App State or Secure Storage
- ✅ Pass API key as parameter at runtime
- ✅ Use environment variables for production

---

## Troubleshooting

### Issue: "Failed to initialize Semaphore API"
**Solution**: 
- Verify API key is correct
- Check internet connection
- Ensure API key has sufficient credits

### Issue: "Invalid phone number"
**Solution**:
- Use format: 09XXXXXXXXX (11 digits)
- Must start with 09
- Must be Philippine mobile number

### Issue: "The selected sendername is invalid"
**Solution**:
- Use default "SEMAPHORE" sender
- Or register custom sender name with Semaphore
- Remove `senderName` parameter to use default

### Issue: Messages not sending
**Solution**:
1. Check scheduled date is in the future
2. Verify message is active (not disabled)
3. Check account has sufficient credits
4. Review logs for error messages

---

## Next Steps

1. ✅ **Testing Complete** - All API functionality verified
2. ⏭️ **Add to FlutterFlow** - Add package dependency
3. ⏭️ **Create Custom Actions** - Implement the 4 custom actions above
4. ⏭️ **Build UI** - Create forms for scheduling
5. ⏭️ **Test in FlutterFlow** - Test with real appointments
6. ⏭️ **Deploy** - Publish your app

---

## Support & Resources

- **Package Repository**: https://github.com/CelestialBrain/schedulersms
- **Semaphore API Docs**: https://www.semaphore.co/docs
- **FlutterFlow Docs**: https://docs.flutterflow.io
- **Test Results**: All tests passed ✅

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025  
**Test Status**: ✅ PASSED (6/6 tests)
