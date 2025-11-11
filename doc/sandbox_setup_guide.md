# Sandbox Environment Setup Guide

## Overview

This guide explains how to set up a sandbox testing environment for your SchedulerSMS dependency before integrating it into your production FlutterFlow project.

---

## Option 1: Python Testing Environment (Fastest)

### ✅ Advantages
- Quick setup (< 5 minutes)
- No Flutter/Dart installation required
- Easy to debug and iterate
- Direct API testing
- Perfect for validating API connectivity

### 📋 Requirements
- Python 3.7+
- `requests` library

### 🚀 Setup Steps

1. **Install Python** (if not already installed):
   ```bash
   # Check if Python is installed
   python3 --version
   
   # If not installed, install Python 3
   # macOS: brew install python3
   # Ubuntu: sudo apt install python3
   # Windows: Download from python.org
   ```

2. **Install required library**:
   ```bash
   pip3 install requests
   ```

3. **Create test script** (`test_sms.py`):
   ```python
   import requests
   
   API_KEY = "your_semaphore_api_key"
   PHONE = "09XXXXXXXXX"
   
   # Test account connection
   response = requests.get(
       "https://api.semaphore.co/api/v4/account",
       params={"apikey": API_KEY}
   )
   print(response.json())
   
   # Send test message
   response = requests.post(
       "https://api.semaphore.co/api/v4/messages",
       data={
           "apikey": API_KEY,
           "number": PHONE,
           "message": "Test message from SchedulerSMS"
       }
   )
   print(response.json())
   ```

4. **Run the test**:
   ```bash
   python3 test_sms.py
   ```

### 📊 Expected Output
```json
{
  "account_id": XXXXX,
  "account_name": "YOUR_CLINIC_NAME",
  "status": "Active",
  "credit_balance": 1010
}
```

---

## Option 2: Flutter Web Test Project (Recommended)

### ✅ Advantages
- Tests actual Dart package code
- Validates database operations
- Tests scheduling logic
- Simulates FlutterFlow environment
- Full feature testing

### 📋 Requirements
- Flutter SDK 3.0+
- Chrome browser
- Git

### 🚀 Setup Steps

1. **Install Flutter** (if not already installed):
   ```bash
   # Check if Flutter is installed
   flutter --version
   
   # If not installed, follow: https://flutter.dev/docs/get-started/install
   ```

2. **Create new Flutter web project**:
   ```bash
   flutter create schedulersms_test
   cd schedulersms_test
   ```

3. **Add package dependency** to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     schedulersms:
       git:
         url: https://github.com/CelestialBrain/schedulersms
         ref: main
   ```

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Create test UI** in `lib/main.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:schedulersms/schedulersms.dart';
   
   void main() {
     runApp(MyApp());
   }
   
   class MyApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'SchedulerSMS Test',
         home: TestPage(),
       );
     }
   }
   
   class TestPage extends StatefulWidget {
     @override
     _TestPageState createState() => _TestPageState();
   }
   
   class _TestPageState extends State<TestPage> {
     final _apiKeyController = TextEditingController();
     final _phoneController = TextEditingController();
     final _messageController = TextEditingController();
     String _status = '';
     
     Future<void> _initialize() async {
       try {
         final scheduler = SchedulerSmsWebSemaphore();
         await scheduler.initialize(apiKey: _apiKeyController.text);
         
         final account = await scheduler.getAccountInfo();
         setState(() {
           _status = 'Connected! Balance: ${account.creditBalance} credits';
         });
       } catch (e) {
         setState(() {
           _status = 'Error: $e';
         });
       }
     }
     
     Future<void> _sendMessage() async {
       try {
         final scheduler = SchedulerSmsWebSemaphore();
         
         // Create customer
         final customer = await scheduler.createCustomer(
           name: 'Test Patient',
           phoneNumber: _phoneController.text,
         );
         
         // Schedule SMS for 1 minute from now
         final scheduledDate = DateTime.now().add(Duration(minutes: 1));
         
         final sms = await scheduler.scheduleSms(
           customer: customer,
           message: _messageController.text,
           scheduledDate: scheduledDate,
         );
         
         setState(() {
           _status = 'Scheduled! ID: ${sms.id}';
         });
       } catch (e) {
         setState(() {
           _status = 'Error: $e';
         });
       }
     }
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('SchedulerSMS Test')),
         body: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             children: [
               TextField(
                 controller: _apiKeyController,
                 decoration: InputDecoration(labelText: 'API Key'),
               ),
               SizedBox(height: 8),
               ElevatedButton(
                 onPressed: _initialize,
                 child: Text('Initialize'),
               ),
               SizedBox(height: 16),
               TextField(
                 controller: _phoneController,
                 decoration: InputDecoration(labelText: 'Phone (09XXXXXXXXX)'),
               ),
               TextField(
                 controller: _messageController,
                 decoration: InputDecoration(labelText: 'Message'),
               ),
               SizedBox(height: 8),
               ElevatedButton(
                 onPressed: _sendMessage,
                 child: Text('Schedule SMS'),
               ),
               SizedBox(height: 16),
               Text(_status),
             ],
           ),
         ),
       );
     }
   }
   ```

6. **Run the app**:
   ```bash
   flutter run -d chrome
   ```

---

## Option 3: FlutterFlow Sandbox Project (Final Testing)

### ✅ Advantages
- Real FlutterFlow environment
- Tests custom actions
- Validates UI integration
- End-to-end testing
- Production-like testing

### 📋 Requirements
- FlutterFlow account
- Web browser

### 🚀 Setup Steps

1. **Create new FlutterFlow project**:
   - Go to https://app.flutterflow.io
   - Click "Create New Project"
   - Choose "Blank" template
   - Name: "SchedulerSMS Test"

2. **Add package dependency**:
   - Go to **Settings & Integrations** → **Project Dependencies**
   - Click **Add Dependency**
   - Select **Git** tab
   - Git URL: `https://github.com/CelestialBrain/schedulersms.git`
   - Click **Add**

3. **Create App State Variables**:
   - Go to **App Settings** → **App State**
   - Add variable: `apiKey` (String)
   - Add variable: `balance` (double)
   - Add variable: `isInitialized` (bool)

4. **Create Custom Action: Initialize**:
   - Go to **Custom Code** → **Actions**
   - Click **Add Action**
   - Name: `initializeSchedulerSms`
   - Parameters: `apiKey` (String)
   - Return Type: `String`
   - Code:
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

5. **Create Custom Action: Schedule Reminder**:
   - Name: `scheduleAppointmentReminder`
   - Parameters:
     - `patientName` (String)
     - `patientPhone` (String)
     - `appointmentDate` (DateTime)
     - `daysAfter` (int)
   - Return Type: `String`
   - Code:
   ```dart
   import 'package:schedulersms/schedulersms.dart';
   
   Future<String> scheduleAppointmentReminder(
     String patientName,
     String patientPhone,
     DateTime appointmentDate,
     int daysAfter,
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
       
       final message = "Hi $patientName, thank you for your appointment! "
           "We hope everything went well. If you have any concerns, contact us!";
       
       final sms = await scheduler.scheduleSms(
         customer: customer,
         message: message,
         scheduledDate: scheduledDate,
       );
       
       return 'Scheduled! ID: ${sms.id}';
     } catch (e) {
       return 'Error: $e';
     }
   }
   ```

6. **Create Test UI**:
   - **Page 1: Setup Page**
     - TextField: API Key input
     - Button: "Initialize" → Call `initializeSchedulerSms`
     - Text: Display result
   
   - **Page 2: Schedule Page**
     - TextField: Patient Name
     - TextField: Patient Phone
     - DateTimePicker: Appointment Date
     - TextField: Days After (number input)
     - Button: "Schedule" → Call `scheduleAppointmentReminder`
     - Text: Display result

7. **Test the flow**:
   - Enter API key and initialize
   - Navigate to Schedule page
   - Fill in patient details
   - Schedule reminder
   - Verify message sends

---

## Comparison: Which Environment to Use?

| Feature | Python | Flutter Web | FlutterFlow |
|---------|--------|-------------|-------------|
| **Setup Time** | 5 min | 15 min | 30 min |
| **Difficulty** | Easy | Medium | Easy |
| **API Testing** | ✅ Full | ✅ Full | ✅ Full |
| **Package Testing** | ❌ No | ✅ Yes | ✅ Yes |
| **UI Testing** | ❌ No | ✅ Yes | ✅ Yes |
| **Production-like** | ❌ No | ⚠️ Partial | ✅ Yes |
| **Best For** | Quick validation | Full testing | Final testing |

### 🎯 Recommended Workflow

1. **Start with Python** (5 min)
   - Validate API key works
   - Test basic message sending
   - Verify phone number format

2. **Move to Flutter Web** (if needed)
   - Test package functionality
   - Validate scheduling logic
   - Test database operations

3. **Finish with FlutterFlow** (final step)
   - Test custom actions
   - Validate UI integration
   - End-to-end testing

---

## Testing Checklist

### ✅ Phase 1: API Validation (Python)
- [ ] API key connects successfully
- [ ] Account balance retrieved
- [ ] Phone number validation works
- [ ] Test message sends
- [ ] Message received on phone

### ✅ Phase 2: Package Testing (Flutter Web)
- [ ] Package initializes
- [ ] Customer can be created
- [ ] SMS can be scheduled
- [ ] Database stores messages
- [ ] Scheduled messages send on time

### ✅ Phase 3: Integration Testing (FlutterFlow)
- [ ] Custom actions work
- [ ] UI forms submit correctly
- [ ] App state updates
- [ ] Messages schedule successfully
- [ ] End-to-end flow works

---

## Test Data Templates

### For Testing Appointment Reminders

**Scenario 1: Recent Appointment (3 days ago)**
```
Patient Name: John Doe
Phone: 09XXXXXXXXX
Appointment Date: [Today - 3 days]
Days After: 3
Expected: Message sends immediately
```

**Scenario 2: Future Appointment**
```
Patient Name: Jane Smith
Phone: 09XXXXXXXXX
Appointment Date: [Today + 1 day]
Days After: 3
Expected: Message scheduled for [Today + 4 days]
```

**Scenario 3: Test Immediate Send**
```
Patient Name: Test Patient
Phone: 09XXXXXXXXX
Appointment Date: [Now - 1 minute]
Days After: 0
Expected: Message sends within 1 minute
```

---

## Environment Variables

### For Python Testing
```bash
export SEMAPHORE_API_KEY="your_api_key_here"
export TEST_PHONE="09XXXXXXXXX"
```

### For Flutter Testing
Create `.env` file:
```
SEMAPHORE_API_KEY=your_api_key_here
TEST_PHONE=09XXXXXXXXX
```

### For FlutterFlow
Store in App State:
- `apiKey`: String (from secure input)
- `testPhone`: String (for testing)

---

## Troubleshooting

### Python Environment Issues
**Error**: `ModuleNotFoundError: No module named 'requests'`
**Solution**: `pip3 install requests`

### Flutter Environment Issues
**Error**: `Package not found`
**Solution**: Run `flutter pub get` and verify internet connection

### FlutterFlow Issues
**Error**: `Custom action fails to compile`
**Solution**: Verify import statement and package dependency added

---

## Next Steps

After completing sandbox testing:

1. ✅ Verify all tests pass
2. ✅ Document any issues found
3. ✅ Configure production API key
4. ✅ Set up production FlutterFlow project
5. ✅ Deploy to production

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025
