# FlutterFlow Testing Guide - Step-by-Step

**Project**: SchedulerSMS for Dental Appointments  
**Purpose**: Complete testing workflow for FlutterFlow  
**Time Required**: 1-2 hours  
**Difficulty**: Beginner-friendly  

---

## Overview

This guide walks you through **exactly what to create** in FlutterFlow to test your SchedulerSMS dependency. Follow each step in order.

---

## Phase 1: Project Setup (10 minutes)

### Step 1.1: Create New FlutterFlow Project

1. Go to https://app.flutterflow.io
2. Click **"Create New Project"**
3. Choose **"Blank"** template
4. Name: **"SchedulerSMS Test"**
5. Click **"Create"**

### Step 1.2: Add Package Dependency

1. Click **Settings & Integrations** (gear icon in left sidebar)
2. Go to **"Project Dependencies"** tab
3. Click **"+ Add Dependency"**
4. Select **"Git"** tab
5. Fill in:
   - **Git URL**: `https://github.com/CelestialBrain/schedulersms.git`
   - **Ref**: `main` (or leave blank)
6. Click **"Add"**
7. Wait for package to be added (green checkmark appears)

### Step 1.3: Create App State Variables

1. Click **App Settings** (gear icon)
2. Go to **"App State"** tab
3. Click **"+ Add Field"**
4. Create these variables:

| Field Name | Type | Default Value | Description |
|------------|------|---------------|-------------|
| `apiKey` | String | `""` | Semaphore API key |
| `isInitialized` | Boolean | `false` | Scheduler initialized |
| `accountBalance` | Double | `0.0` | Credit balance |
| `statusMessage` | String | `""` | Status messages |

5. Click **"Save"**

---

## Phase 2: Create Custom Actions (30 minutes)

### Step 2.1: Custom Action - Initialize Scheduler

1. Go to **Custom Code** → **Actions** (in left sidebar)
2. Click **"+ Add Action"**
3. Fill in:
   - **Action Name**: `initializeSchedulerSms`
   - **Description**: `Initialize SchedulerSMS with Semaphore API`

4. **Add Parameters**:
   - Click **"+ Add Parameter"**
   - Name: `apiKey`
   - Type: `String`
   - Required: ✅ Yes

5. **Set Return Type**:
   - Return Type: `String`

6. **Add Code**:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> initializeSchedulerSms(String apiKey) async {
  try {
    // Initialize the scheduler
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.initialize(apiKey: apiKey);
    
    // Get account info to verify connection
    final account = await scheduler.getAccountInfo();
    
    // Return success message with balance
    return 'Success! Balance: ${account.creditBalance} credits';
  } catch (e) {
    // Return error message
    return 'Error: ${e.toString()}';
  }
}
```

7. Click **"Save"**

---

### Step 2.2: Custom Action - Get Account Balance

1. Click **"+ Add Action"**
2. Fill in:
   - **Action Name**: `getAccountBalance`
   - **Description**: `Get Semaphore account credit balance`

3. **No Parameters Needed**

4. **Set Return Type**:
   - Return Type: `Double`

5. **Add Code**:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<double> getAccountBalance() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final account = await scheduler.getAccountInfo();
    return account.creditBalance;
  } catch (e) {
    // Return 0 if error
    return 0.0;
  }
}
```

6. Click **"Save"**

---

### Step 2.3: Custom Action - Schedule Appointment Reminder

1. Click **"+ Add Action"**
2. Fill in:
   - **Action Name**: `scheduleAppointmentReminder`
   - **Description**: `Schedule SMS reminder after appointment`

3. **Add Parameters**:

| Parameter Name | Type | Required | Description |
|----------------|------|----------|-------------|
| `patientName` | String | ✅ Yes | Patient's full name |
| `patientPhone` | String | ✅ Yes | Phone (09XXXXXXXXX) |
| `appointmentDate` | DateTime | ✅ Yes | Appointment date/time |
| `daysAfter` | Integer | ✅ Yes | Days after to send |
| `clinicName` | String | ✅ Yes | Your clinic name |

4. **Set Return Type**:
   - Return Type: `String`

5. **Add Code**:

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
      // Create new customer
      customer = await scheduler.createCustomer(
        name: patientName,
        phoneNumber: patientPhone,
      );
    }
    
    // Calculate scheduled date
    final scheduledDate = appointmentDate.add(Duration(days: daysAfter));
    
    // Create message
    final message = 'Hi $patientName, thank you for visiting $clinicName! '
        'We hope your appointment on ${appointmentDate.month}/${appointmentDate.day} went well. '
        'Please remember to follow the post-appointment care instructions. '
        'If you have any concerns, feel free to contact us!';
    
    // Schedule the SMS
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

6. Click **"Save"**

---

### Step 2.4: Custom Action - Validate Phone Number

1. Click **"+ Add Action"**
2. Fill in:
   - **Action Name**: `validatePhilippinePhone`
   - **Description**: `Validate Philippine mobile number format`

3. **Add Parameters**:
   - Name: `phoneNumber`
   - Type: `String`
   - Required: ✅ Yes

4. **Set Return Type**:
   - Return Type: `Boolean`

5. **Add Code**:

```dart
bool validatePhilippinePhone(String phoneNumber) {
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

6. Click **"Save"**

---

## Phase 3: Create UI Pages (30 minutes)

### Step 3.1: Setup Page (Initialize API)

1. Go to **Pages** in left sidebar
2. Click on **"HomePage"** (default page)
3. Rename to **"SetupPage"**

#### Add Widgets:

**Layout Structure:**
```
Column (Main Axis: Center, Cross Axis: Center)
├─ Text: "SchedulerSMS Setup"
├─ TextField: apiKeyField
├─ Button: "Initialize"
└─ Text: statusText
```

**Detailed Steps:**

1. **Delete default widgets** in the page

2. **Add Column**:
   - Drag **Column** to canvas
   - Properties:
     - Main Axis Alignment: `Center`
     - Cross Axis Alignment: `Center`
     - Padding: `24` all sides

3. **Add Title Text**:
   - Drag **Text** into Column
   - Text: `"SchedulerSMS Setup"`
   - Font Size: `24`
   - Font Weight: `Bold`
   - Margin Bottom: `32`

4. **Add API Key TextField**:
   - Drag **TextField** into Column
   - Label: `"Semaphore API Key"`
   - Hint: `"Enter your API key"`
   - Width: `300`
   - Margin Bottom: `16`
   - **Create Widget State**:
     - Click on TextField
     - Right panel → **Widget State**
     - Name: `apiKeyField`
     - Type: `Text Field Controller`

5. **Add Initialize Button**:
   - Drag **Button** into Column
   - Text: `"Initialize Scheduler"`
   - Width: `300`
   - Margin Bottom: `16`
   - **Add Actions** (click button → Actions tab):
     
     **Action 1: Call Custom Action**
     - Action: `Custom Action`
     - Select: `initializeSchedulerSms`
     - Parameters:
       - `apiKey`: `Widget State → apiKeyField`
     - Action Output Variable Name: `initResult`
     
     **Action 2: Update App State**
     - Action: `Update App State`
     - Field: `apiKey`
     - Value: `Widget State → apiKeyField`
     
     **Action 3: Update App State**
     - Action: `Update App State`
     - Field: `isInitialized`
     - Value: `true`
     
     **Action 4: Update App State**
     - Action: `Update App State`
     - Field: `statusMessage`
     - Value: `Action Outputs → initResult`
     
     **Action 5: Call Custom Action**
     - Action: `Custom Action`
     - Select: `getAccountBalance`
     - Action Output Variable Name: `balance`
     
     **Action 6: Update App State**
     - Action: `Update App State`
     - Field: `accountBalance`
     - Value: `Action Outputs → balance`

6. **Add Status Text**:
   - Drag **Text** into Column
   - Text: `App State → statusMessage`
   - Font Size: `16`
   - Color: `Green`
   - Margin Bottom: `16`

7. **Add Balance Text**:
   - Drag **Text** into Column
   - Text: `"Balance: "` + `App State → accountBalance` + `" credits"`
   - Font Size: `16`
   - Font Weight: `Bold`

8. **Add Navigation Button**:
   - Drag **Button** into Column
   - Text: `"Go to Schedule Page"`
   - Margin Top: `32`
   - **Conditional Visibility**:
     - Condition: `App State → isInitialized` equals `true`
   - **Add Action**:
     - Action: `Navigate To`
     - Page: `SchedulePage` (we'll create this next)

---

### Step 3.2: Schedule Page (Schedule Reminders)

1. Go to **Pages** in left sidebar
2. Click **"+ Add Page"**
3. Name: **"SchedulePage"**
4. Click **"Create"**

#### Add Widgets:

**Layout Structure:**
```
Column (Scrollable)
├─ Text: "Schedule Appointment Reminder"
├─ TextField: patientNameField
├─ TextField: patientPhoneField
├─ DateTimePicker: appointmentDatePicker
├─ TextField: daysAfterField (number)
├─ TextField: clinicNameField
├─ Button: "Schedule Reminder"
├─ Text: resultText
└─ Button: "Back to Setup"
```

**Detailed Steps:**

1. **Add Column**:
   - Drag **Column** to canvas
   - Properties:
     - Main Axis Alignment: `Start`
     - Cross Axis Alignment: `Stretch`
     - Padding: `24` all sides

2. **Add Title**:
   - Drag **Text** into Column
   - Text: `"Schedule Appointment Reminder"`
   - Font Size: `24`
   - Font Weight: `Bold`
   - Margin Bottom: `24`

3. **Add Patient Name Field**:
   - Drag **TextField** into Column
   - Label: `"Patient Name"`
   - Hint: `"John Doe"`
   - Margin Bottom: `12`
   - Widget State Name: `patientNameField`

4. **Add Patient Phone Field**:
   - Drag **TextField** into Column
   - Label: `"Patient Phone"`
   - Hint: `"09171234567"`
   - Keyboard Type: `Phone`
   - Margin Bottom: `12`
   - Widget State Name: `patientPhoneField`

5. **Add Appointment Date Picker**:
   - Drag **DateTimePicker** into Column
   - Label: `"Appointment Date"`
   - Mode: `Date and Time`
   - Margin Bottom: `12`
   - Widget State Name: `appointmentDatePicker`

6. **Add Days After Field**:
   - Drag **TextField** into Column
   - Label: `"Days After Appointment"`
   - Hint: `"3"`
   - Keyboard Type: `Number`
   - Margin Bottom: `12`
   - Widget State Name: `daysAfterField`

7. **Add Clinic Name Field**:
   - Drag **TextField** into Column
   - Label: `"Clinic Name"`
   - Hint: `"Your Dental Clinic"`
   - Margin Bottom: `24`
   - Widget State Name: `clinicNameField`

8. **Add Schedule Button**:
   - Drag **Button** into Column
   - Text: `"Schedule Reminder"`
   - Margin Bottom: `16`
   - **Add Actions**:
     
     **Action 1: Validate Phone**
     - Action: `Custom Action`
     - Select: `validatePhilippinePhone`
     - Parameters:
       - `phoneNumber`: `Widget State → patientPhoneField`
     - Action Output Variable Name: `isValid`
     
     **Action 2: Conditional**
     - Condition: `Action Outputs → isValid` equals `false`
     - **True Actions**:
       - Action: `Show Snackbar`
       - Message: `"Invalid phone number. Use format: 09XXXXXXXXX"`
       - Duration: `4 seconds`
       - Action: `Stop Executing Actions`
     
     **Action 3: Call Custom Action**
     - Action: `Custom Action`
     - Select: `scheduleAppointmentReminder`
     - Parameters:
       - `patientName`: `Widget State → patientNameField`
       - `patientPhone`: `Widget State → patientPhoneField`
       - `appointmentDate`: `Widget State → appointmentDatePicker`
       - `daysAfter`: `Widget State → daysAfterField` (convert to int)
       - `clinicName`: `Widget State → clinicNameField`
     - Action Output Variable Name: `scheduleResult`
     
     **Action 4: Update App State**
     - Action: `Update App State`
     - Field: `statusMessage`
     - Value: `Action Outputs → scheduleResult`
     
     **Action 5: Show Snackbar**
     - Message: `Action Outputs → scheduleResult`
     - Duration: `4 seconds`
     
     **Action 6: Clear Form** (Optional)
     - Action: `Clear Text Field`
     - Select: `patientNameField`
     - Repeat for other fields

9. **Add Result Text**:
   - Drag **Text** into Column
   - Text: `App State → statusMessage`
   - Font Size: `14`
   - Margin Bottom: `16`

10. **Add Back Button**:
    - Drag **Button** into Column
    - Text: `"Back to Setup"`
    - Style: `Outlined`
    - **Add Action**:
      - Action: `Navigate To`
      - Page: `SetupPage`

---

## Phase 4: Testing Workflow (20 minutes)

### Test 1: Initialize Scheduler

1. Click **"Run"** (play button) in top right
2. Choose **"Test Mode"** or **"Run"**
3. On Setup Page:
   - Enter your API key: `YOUR_SEMAPHORE_API_KEY`
   - Click **"Initialize Scheduler"**
4. **Expected Result**:
   - Status message: "Success! Balance: XXXX credits"
   - Balance displays correctly
   - "Go to Schedule Page" button appears

**✅ Pass Criteria**: No errors, balance shows correctly

---

### Test 2: Validate Phone Number

1. Click **"Go to Schedule Page"**
2. Fill in form:
   - Patient Name: `Test Patient`
   - Patient Phone: `1234567890` (invalid)
   - Appointment Date: Any date
   - Days After: `3`
   - Clinic Name: `Test Clinic`
3. Click **"Schedule Reminder"**
4. **Expected Result**:
   - Snackbar: "Invalid phone number. Use format: 09XXXXXXXXX"

**✅ Pass Criteria**: Validation works, error message shows

---

### Test 3: Schedule Test Reminder (Immediate)

1. Fill in form with valid data:
   - Patient Name: `John Doe`
   - Patient Phone: `09XXXXXXXXX` (your test number)
   - Appointment Date: **1 minute ago**
   - Days After: `0` (send immediately)
   - Clinic Name: `Test Dental Clinic`
2. Click **"Schedule Reminder"**
3. **Expected Result**:
   - Snackbar: "Scheduled! SMS ID: XXXXX"
   - Status message updates
4. **Check your phone** within 2-3 minutes for SMS

**✅ Pass Criteria**: Message scheduled, SMS received on phone

---

### Test 4: Schedule Future Reminder

1. Fill in form:
   - Patient Name: `Jane Smith`
   - Patient Phone: `09XXXXXXXXX`
   - Appointment Date: **Today**
   - Days After: `3` (send in 3 days)
   - Clinic Name: `Your Clinic`
2. Click **"Schedule Reminder"**
3. **Expected Result**:
   - Success message
   - Message scheduled for 3 days from now

**✅ Pass Criteria**: No errors, message scheduled correctly

---

### Test 5: Check Balance After Sending

1. Go back to **Setup Page**
2. Click **"Initialize Scheduler"** again
3. **Expected Result**:
   - Balance decreased by number of credits used
   - (1 credit for short messages, 2+ for longer messages)

**✅ Pass Criteria**: Balance reflects sent messages

---

## Phase 5: Troubleshooting

### Issue: "Failed to initialize"

**Possible Causes**:
- Invalid API key
- No internet connection
- Package not added correctly

**Solutions**:
1. Verify API key is correct
2. Check internet connection
3. Re-add package dependency
4. Rebuild project (Settings → Rebuild)

---

### Issue: "Invalid phone number" for valid number

**Possible Causes**:
- Phone number has spaces or dashes
- Wrong format

**Solutions**:
1. Use format: `09XXXXXXXXX` (no spaces, dashes, or +63)
2. Remove all formatting
3. Must be exactly 11 digits

---

### Issue: Message not received

**Possible Causes**:
- Scheduled for future date
- Phone number incorrect
- Network delay
- Insufficient credits

**Solutions**:
1. Check scheduled date is correct
2. Verify phone number
3. Wait 5-10 minutes (network delay)
4. Check account balance
5. Check Semaphore dashboard for delivery status

---

### Issue: "Package not found" error

**Solutions**:
1. Go to Settings → Project Dependencies
2. Verify Git URL is correct
3. Click "Refresh" or re-add package
4. Wait for package to download
5. Rebuild project

---

## Testing Checklist

Use this checklist to ensure everything works:

### Setup Phase
- [ ] Package dependency added successfully
- [ ] App State variables created
- [ ] All 4 custom actions created and saved
- [ ] Setup Page UI created
- [ ] Schedule Page UI created

### Functionality Testing
- [ ] Initialize with API key works
- [ ] Account balance displays correctly
- [ ] Phone validation rejects invalid numbers
- [ ] Phone validation accepts valid numbers
- [ ] Can schedule immediate reminder (0 days)
- [ ] Can schedule future reminder (3 days)
- [ ] SMS received on test phone
- [ ] Balance decreases after sending
- [ ] Error messages display correctly
- [ ] Navigation between pages works

### Edge Cases
- [ ] Empty fields show validation errors
- [ ] Invalid API key shows error
- [ ] Network error handled gracefully
- [ ] Multiple messages can be scheduled
- [ ] App state persists between pages

---

## Next Steps After Testing

### If All Tests Pass ✅

1. **Document your findings**
   - Note any issues encountered
   - Record successful test results
   - Save test phone numbers used

2. **Prepare for production**
   - Create production FlutterFlow project
   - Copy custom actions to production
   - Update with production API key
   - Test with real patient data

3. **Add enhancements**
   - Message templates
   - Patient management page
   - Message history view
   - Bulk scheduling

### If Tests Fail ❌

1. **Review error messages**
   - Screenshot any errors
   - Note which step failed
   - Check console logs

2. **Verify configuration**
   - API key correct
   - Phone number format
   - Package dependency added
   - Custom actions saved

3. **Get help**
   - Check documentation in GitHub repo
   - Review Semaphore API docs
   - Contact support if needed

---

## Quick Reference

### Custom Actions Created
1. `initializeSchedulerSms(apiKey)` → String
2. `getAccountBalance()` → Double
3. `scheduleAppointmentReminder(...)` → String
4. `validatePhilippinePhone(phoneNumber)` → Boolean

### App State Variables
- `apiKey` (String)
- `isInitialized` (Boolean)
- `accountBalance` (Double)
- `statusMessage` (String)

### Pages Created
1. **SetupPage** - Initialize and configure
2. **SchedulePage** - Schedule reminders

### Test Data
- **Test Phone**: `09XXXXXXXXX` (your number)
- **Test Patient**: `John Doe`
- **Test Clinic**: `Test Dental Clinic`
- **Immediate Send**: Appointment date = 1 min ago, Days after = 0
- **Future Send**: Appointment date = today, Days after = 3

---

## Time Estimates

| Phase | Task | Time |
|-------|------|------|
| 1 | Project Setup | 10 min |
| 2 | Custom Actions | 30 min |
| 3 | UI Pages | 30 min |
| 4 | Testing | 20 min |
| **Total** | | **~90 min** |

---

## Support

If you encounter issues:

1. **Check Documentation**:
   - `doc/TEST_REPORT.md` - Test results
   - `doc/flutterflow_integration_guide.md` - Integration guide
   - `doc/sandbox_setup_guide.md` - Setup options

2. **Review Logs**:
   - FlutterFlow console (bottom panel)
   - Browser developer console (F12)

3. **Verify Configuration**:
   - Package dependency added
   - API key correct
   - Phone number format valid

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025  
**Estimated Completion Time**: 90 minutes  
**Difficulty**: Beginner-friendly ⭐⭐☆☆☆
