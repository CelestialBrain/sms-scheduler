# SchedulerSMS Code Examination Summary

## Project Overview

The **schedulersms** project is a Flutter package designed to schedule SMS messages for dental appointments (or any other appointment-based system). It integrates with **Semaphore SMS API**, a Philippine-based SMS service provider, and is specifically designed to work with **FlutterFlow** projects.

## Key Components

### 1. **Dart/Flutter Package** (`/lib` directory)
The main Flutter package contains:

- **`SchedulerSmsWebSemaphore`** - Main scheduler class for web applications
- **`SemaphoreApiClient`** - API client for Semaphore SMS service
- **Customer Management** - Database and models for managing customer information
- **SMS Database** - Local storage for scheduled messages
- **Logger System** - Comprehensive logging for debugging

### 2. **Backend API** (`/backend_api` directory)
A Node.js/Express backend for handling:
- eSIM purchases (via Airalo API)
- Load purchases for Philippine networks
- Secure API key management

**Note**: This backend API is for eSIM/load features, NOT for the SMS scheduling functionality.

### 3. **Core Functionality**

#### SMS Scheduling Flow:
1. **Initialize** the scheduler with Semaphore API key
2. **Create/Manage Customers** with phone numbers
3. **Schedule SMS** for specific dates/times
4. **Periodic Check** (every 1 minute) sends pending messages
5. **Status Updates** via streams for real-time feedback

#### Key Classes:

**`SchedulerSmsWebSemaphore`** (Main Scheduler)
- `initialize(apiKey, senderName, usePriorityQueue)` - Initialize with API credentials
- `scheduleSms(customer, message, scheduledDate)` - Schedule a new SMS
- `checkAndSendPendingSms()` - Check and send due messages
- `getAccountInfo()` - Get Semaphore account balance and info
- Customer management methods (create, update, delete, get)

**`SemaphoreApiClient`** (API Integration)
- `sendMessage()` - Send regular SMS (1 credit)
- `sendPriorityMessage()` - Send priority SMS (2 credits, bypasses queue)
- `sendBulkMessages()` - Send to multiple recipients
- `sendOtpMessage()` - Send OTP messages
- `getAccount()` - Get account information
- `getMessage(messageId)` - Retrieve message status

**`Customer`** Model
- `id`, `name`, `phoneNumber`, `email`
- `createdAt`, `updatedAt`
- `tags`, `notes`, `metadata`

**`ScheduledSMS`** Model
- `id`, `customerId`, `recipient`, `message`
- `scheduledDate`, `sentAt`, `status`
- `priority`, `retryCount`, `errorMessage`
- `senderName`, `tags`

## FlutterFlow Integration

The package is designed to be used as a **Custom Action** in FlutterFlow projects. Key custom actions needed:

1. **`initializeSchedulerSmsSemaphore(apiKey)`** - Initialize on app start
2. **`createCustomer(name, phoneNumber, email)`** - Create customer records
3. **`scheduleSmsForCustomer(customerId, message, scheduledDate)`** - Schedule with customer ID
4. **`scheduleSmsDirectly(phoneNumber, message, scheduledDate)`** - Schedule without pre-existing customer
5. **`getAllCustomers()`** - Get customer list
6. **`getAccountBalance()`** - Check Semaphore credits

## Semaphore API Details

### Base URL
```
https://api.semaphore.co/api/v4
```

### Key Endpoints Used
- `POST /messages` - Send SMS
- `POST /priority` - Send priority SMS
- `POST /otp` - Send OTP
- `GET /account` - Get account info
- `GET /messages/{id}` - Get message status

### Authentication
- Uses API key passed in request body or query string
- API key should be stored securely and passed at runtime

### Message Costs
- Regular SMS: **1 credit** per 160 characters
- Priority SMS: **2 credits** per 160 characters
- OTP SMS: **2 credits** per 160 characters

### Rate Limits
- Send Messages: 120 requests/minute
- Get Messages: 30 requests/minute
- Account Info: 2 requests/minute

### Phone Number Format
- Philippine format: `09XXXXXXXXX` (11 digits starting with 09)
- Supported networks: Globe, Smart, DITO

## Testing Requirements

### Environment Variables Needed
For the backend API (if testing eSIM/load features):
- `PORT` - Server port (default: 3000)
- `AIRALO_API_KEY` - Airalo API key
- `LOAD_API_UID` - Load provider UID
- `LOAD_API_PASSWORD` - Load provider password
- `LOAD_COMPANY_PREFIX` - Company prefix for transactions

### For SchedulerSMS Testing
- **Semaphore API Key** - Required for all SMS operations
- **Test Phone Number** - Philippine mobile number (09XXXXXXXXX format)
- **Sender Name** - Optional, defaults to "SEMAPHORE"

### Sandbox FlutterFlow Project Parameters

To test the dependency in a sandbox FlutterFlow project, you need:

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `apiKey` | String | Semaphore API key | `your_semaphore_api_key` |
| `senderName` | String | Sender name for SMS | `DentalClinic` |
| `customerName` | String | Patient/customer name | `John Doe` |
| `customerPhone` | String | Philippine mobile number | `09171234567` |
| `appointmentDate` | DateTime | Date of appointment | `2025-11-15 10:00:00` |
| `daysAfter` | int | Days after appointment to send | `3` |
| `messageTemplate` | String | Message content | `Hi {name}, hope your visit went well!` |

## Testing Approach

### Option 1: Python Script Testing (Recommended)
Create a Python script to simulate the FlutterFlow custom actions:
1. Test Semaphore API connectivity
2. Test message scheduling
3. Test customer management
4. Verify message sending

### Option 2: Flutter Test Project
Create a minimal Flutter web project:
1. Add the package as a dependency
2. Create test UI with forms
3. Test all custom actions
4. Verify database operations

### Option 3: Direct API Testing
Use Postman or curl to test Semaphore API directly:
1. Test account info endpoint
2. Test message sending
3. Verify response format

## Key Files to Review

1. **`/lib/src/schedulersms_web_semaphore.dart`** - Main scheduler implementation
2. **`/lib/src/api/semaphore_api_client.dart`** - Semaphore API client
3. **`/doc/FLUTTERFLOW_SEMAPHORE_GUIDE.md`** - Integration guide
4. **`/example/flutterflow_custom_actions.dart`** - Example custom actions
5. **`/lib/src/models/scheduled_sms.dart`** - SMS data model
6. **`/lib/src/models/customer.dart`** - Customer data model

## Dental Appointment Use Case

For your specific dental appointment reminder system:

1. **After Appointment**: When a patient completes an appointment, create a customer record and schedule an SMS for X days later
2. **Message Template**: "Hi {customerName}, thank you for visiting {clinicName}! We hope your dental appointment went well. Please remember to [follow-up instructions]."
3. **Scheduling Logic**: `scheduledDate = appointmentDate + Duration(days: daysAfter)`
4. **Automatic Sending**: The periodic check (every 1 minute) will automatically send messages when due

## Security Considerations

1. **API Key Management**: Never hardcode API keys in the repository
2. **Runtime Configuration**: Pass API key from FlutterFlow app state or secure storage
3. **HTTPS**: Always use HTTPS in production
4. **Input Validation**: Validate phone numbers before scheduling
5. **Rate Limiting**: Respect Semaphore API rate limits

## Next Steps for Testing

1. ✅ Code examination complete
2. ⏳ Set up Python testing environment
3. ⏳ Test Semaphore API connectivity with your API key
4. ⏳ Create test script for scheduling and sending
5. ⏳ Verify message delivery
6. ⏳ Document test results and recommendations
