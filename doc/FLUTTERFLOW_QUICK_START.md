# FlutterFlow Quick Start - SchedulerSMS Testing

**⏱️ Time**: 90 minutes  
**📱 What You'll Build**: SMS appointment reminder system  
**✅ Result**: Working SMS scheduler in FlutterFlow  

---

## What You Need

- [ ] FlutterFlow account
- [ ] Your Semaphore API key: `YOUR_SEMAPHORE_API_KEY`
- [ ] Test phone number: `09XXXXXXXXX`
- [ ] 90 minutes of time

---

## Quick Setup (10 min)

### 1. Create Project
- Go to https://app.flutterflow.io
- Create new project: "SchedulerSMS Test"

### 2. Add Package
- Settings → Project Dependencies
- Add Git dependency: `https://github.com/CelestialBrain/schedulersms.git`

### 3. Create App State
- App Settings → App State
- Add 4 variables:
  - `apiKey` (String)
  - `isInitialized` (Boolean)
  - `accountBalance` (Double)
  - `statusMessage` (String)

---

## Custom Actions to Create (30 min)

### Action 1: initializeSchedulerSms
**Parameters**: `apiKey` (String)  
**Returns**: String

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> initializeSchedulerSms(String apiKey) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.initialize(apiKey: apiKey);
    final account = await scheduler.getAccountInfo();
    return 'Success! Balance: ${account.creditBalance} credits';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}
```

---

### Action 2: getAccountBalance
**Parameters**: None  
**Returns**: Double

```dart
import 'package:schedulersms/schedulersms.dart';

Future<double> getAccountBalance() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final account = await scheduler.getAccountInfo();
    return account.creditBalance;
  } catch (e) {
    return 0.0;
  }
}
```

---

### Action 3: scheduleAppointmentReminder
**Parameters**: 
- `patientName` (String)
- `patientPhone` (String)
- `appointmentDate` (DateTime)
- `daysAfter` (Integer)
- `clinicName` (String)

**Returns**: String

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
    
    Customer? customer = await scheduler.getCustomerByPhone(patientPhone);
    if (customer == null) {
      customer = await scheduler.createCustomer(
        name: patientName,
        phoneNumber: patientPhone,
      );
    }
    
    final scheduledDate = appointmentDate.add(Duration(days: daysAfter));
    
    final message = 'Hi $patientName, thank you for visiting $clinicName! '
        'We hope your appointment on ${appointmentDate.month}/${appointmentDate.day} went well. '
        'Please remember to follow the post-appointment care instructions. '
        'If you have any concerns, feel free to contact us!';
    
    final sms = await scheduler.scheduleSms(
      customer: customer,
      message: message,
      scheduledDate: scheduledDate,
    );
    
    return 'Scheduled! SMS ID: ${sms.id}';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}
```

---

### Action 4: validatePhilippinePhone
**Parameters**: `phoneNumber` (String)  
**Returns**: Boolean

```dart
bool validatePhilippinePhone(String phoneNumber) {
  String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (cleaned.startsWith('63')) {
    cleaned = '0${cleaned.substring(2)}';
  } else if (cleaned.startsWith('9') && cleaned.length == 10) {
    cleaned = '0$cleaned';
  }
  
  if (cleaned.length != 11) return false;
  if (!cleaned.startsWith('09')) return false;
  
  return true;
}
```

---

## Pages to Build (30 min)

### Page 1: SetupPage

**Widgets**:
```
Column
├─ Text: "SchedulerSMS Setup" (size 24, bold)
├─ TextField: apiKeyField (label: "Semaphore API Key")
├─ Button: "Initialize Scheduler"
│  └─ Actions:
│     1. Call initializeSchedulerSms(apiKeyField)
│     2. Update App State: apiKey = apiKeyField
│     3. Update App State: isInitialized = true
│     4. Update App State: statusMessage = result
│     5. Call getAccountBalance()
│     6. Update App State: accountBalance = result
├─ Text: App State → statusMessage
├─ Text: "Balance: " + accountBalance + " credits"
└─ Button: "Go to Schedule Page" (visible if isInitialized)
   └─ Action: Navigate to SchedulePage
```

---

### Page 2: SchedulePage

**Widgets**:
```
Column (scrollable)
├─ Text: "Schedule Appointment Reminder" (size 24, bold)
├─ TextField: patientNameField (label: "Patient Name")
├─ TextField: patientPhoneField (label: "Patient Phone")
├─ DateTimePicker: appointmentDatePicker
├─ TextField: daysAfterField (label: "Days After", type: number)
├─ TextField: clinicNameField (label: "Clinic Name")
├─ Button: "Schedule Reminder"
│  └─ Actions:
│     1. Call validatePhilippinePhone(patientPhoneField)
│     2. If invalid: Show snackbar "Invalid phone", stop
│     3. Call scheduleAppointmentReminder(all fields)
│     4. Update App State: statusMessage = result
│     5. Show snackbar with result
├─ Text: App State → statusMessage
└─ Button: "Back to Setup"
   └─ Action: Navigate to SetupPage
```

---

## Testing (20 min)

### Test 1: Initialize ✅
1. Run project
2. Enter API key
3. Click "Initialize"
4. **Expected**: "Success! Balance: XXX credits"

### Test 2: Invalid Phone ✅
1. Go to Schedule Page
2. Enter phone: `1234567890`
3. Click "Schedule"
4. **Expected**: "Invalid phone number" error

### Test 3: Send Immediate SMS ✅
1. Enter valid data:
   - Name: `Test Patient`
   - Phone: `09XXXXXXXXX` (your number)
   - Date: **1 minute ago**
   - Days: `0`
   - Clinic: `Test Clinic`
2. Click "Schedule"
3. **Expected**: SMS received on phone in 2-3 minutes

### Test 4: Schedule Future SMS ✅
1. Enter valid data:
   - Date: **Today**
   - Days: `3`
2. Click "Schedule"
3. **Expected**: "Scheduled!" message, no errors

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Failed to initialize" | Check API key, internet connection |
| "Invalid phone number" | Use format: `09XXXXXXXXX` (11 digits) |
| Message not received | Wait 5-10 minutes, check phone number |
| Package not found | Re-add Git dependency, rebuild project |

---

## What's Next?

After testing works:

1. ✅ **Production Setup**
   - Create production FlutterFlow project
   - Copy custom actions
   - Use production API key

2. ✅ **Add Features**
   - Message templates
   - Patient list view
   - Message history
   - Bulk scheduling

3. ✅ **Deploy**
   - Test with real patients
   - Train staff
   - Monitor delivery rates

---

## Need More Details?

See full documentation in GitHub:
- `doc/FLUTTERFLOW_TESTING_STEPS.md` - Complete step-by-step guide
- `doc/flutterflow_integration_guide.md` - Integration details
- `doc/TEST_REPORT.md` - Test results

---

**Quick Start Version**: 1.0  
**Time to Complete**: ~90 minutes  
**Difficulty**: ⭐⭐☆☆☆ (Beginner-friendly)
