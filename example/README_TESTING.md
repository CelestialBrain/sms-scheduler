# Semaphore SMS Testing Guide

This directory contains testing utilities and examples for verifying Semaphore SMS integration.

## Files

### `semaphore_live_test.dart`
A command-line script for live API testing.

**Usage:**
```bash
# Check account balance only
dart run example/semaphore_live_test.dart

# Send a test SMS to a specific number
dart run example/semaphore_live_test.dart 09171234567
```

**Features:**
- Connects to real Semaphore API
- Displays account information and credit balance
- Optionally sends a test SMS to verify delivery
- Supports API key from environment variable: `SEMAPHORE_API_KEY`

**⚠️ WARNING**: This uses the real Semaphore API and will consume credits when sending SMS.

## API Key Configuration

The test script accepts the API key in two ways:

1. **Environment Variable** (Recommended):
   ```bash
   SEMAPHORE_API_KEY=your-key dart run example/semaphore_live_test.dart
   ```

2. **Default Test Key**: 
   If no environment variable is set, uses `1fd72138299086e8fc5656a9826ac7e9`

**SECURITY NOTE**: The default key is for convenience during testing only. For production:
- Always use environment variables or secure storage
- Never commit API keys to public repositories
- Rotate keys regularly

## Testing from Code

Use the `SemaphoreTestHelper` class for programmatic testing:

```dart
import 'package:schedulersms/schedulersms.dart';

void main() async {
  final helper = SemaphoreTestHelper(apiKey: 'your-api-key');
  await helper.initialize();
  
  // Check balance
  final balance = await helper.getAccountBalance();
  print('Balance: $balance credits');
  
  // Send test SMS
  final result = await helper.sendTestSms(
    phoneNumber: '09171234567',
    message: 'Test message',
  );
  print('Sent! Message ID: ${result.messageId}');
  
  helper.dispose();
}
```

## FlutterFlow Testing

To test from FlutterFlow, create a custom action:

```dart
import 'package:schedulersms/schedulersms.dart';

Future<String> testSemaphoreConnection(String apiKey) async {
  final helper = SemaphoreTestHelper(apiKey: apiKey);
  
  try {
    await helper.initialize();
    final account = await helper.getAccountInfo();
    helper.dispose();
    
    return 'Connected!\n'
           'Account: ${account.accountName}\n'
           'Balance: ${account.creditBalance} credits\n'
           'Status: ${account.status}';
  } catch (e) {
    return 'Connection failed: $e';
  }
}
```

## Testing Best Practices

1. **Start with Balance Check**: Always check your account balance first before sending SMS
2. **Use Test Numbers**: Send test messages to your own phone number first
3. **Monitor Credits**: Keep track of SMS credit consumption during testing
4. **Validate Phone Numbers**: Ensure phone numbers are in correct Philippine format (09XXXXXXXXX)
5. **Handle Errors**: Implement proper error handling for API failures

## Expected Output

When running the test script successfully:

```
======================================================================
Semaphore SMS Live Test
======================================================================

⚠️  Using default test API key
   To use your own key, set: SEMAPHORE_API_KEY=your-key

Initializing Semaphore test helper...
✓ Successfully connected to Semaphore API

----------------------------------------------------------------------
Account Information
----------------------------------------------------------------------
Account Name:    Your Account Name
Account ID:      12345
Status:          Active
Credit Balance:  100.0 credits

----------------------------------------------------------------------
How to Send a Test SMS
----------------------------------------------------------------------
Run this script with a phone number argument:
  dart run example/semaphore_live_test.dart 09171234567

This will send a test message to verify end-to-end delivery.

======================================================================
Test completed successfully!
======================================================================
```

## Troubleshooting

### "Failed to connect to Semaphore API"
- Check your internet connection
- Verify the API key is correct
- Ensure Semaphore service is operational

### "Invalid phone number format"
- Use Philippine format: 09XXXXXXXXX (11 digits)
- Supported networks: Globe, Smart, DITO

### "Insufficient credits"
- Check your account balance
- Purchase more credits at semaphore.co

## Additional Resources

- [README_SEMAPHORE.md](../README_SEMAPHORE.md) - Complete Semaphore integration guide
- [Semaphore API Documentation](https://semaphore.co/docs) - Official API docs
- [flutterflow_custom_actions.dart](flutterflow_custom_actions.dart) - FlutterFlow integration examples
