# Security Update: API Key Management

## Overview

This update removes hardcoded API keys from the repository and requires them to be passed as parameters at runtime. This is a **breaking change** that improves security by ensuring sensitive credentials are not exposed in public repositories.

## What Changed

### Before
```dart
// API key was hardcoded in SemaphoreConfig
class SemaphoreConfig {
  static const String apiKey = '1fd72138299086e8fc5656a9826ac7e9';
}

// Initialize without providing API key
await scheduler.initialize();
```

### After
```dart
// API key is passed as a required parameter
await scheduler.initialize(
  apiKey: 'your-api-key-here',
  senderName: 'YourBrand', // Optional
);
```

## Migration Guide

If you're using this package, you need to update your code:

1. **Remove any hardcoded API keys** from your codebase
2. **Update initialization calls** to include the `apiKey` parameter
3. **Store API keys securely** using one of these methods:
   - FlutterFlow App State (for FlutterFlow apps)
   - Environment variables
   - Secure storage packages (e.g., `flutter_secure_storage`)
   - Backend API that provides the key after authentication

## Example: FlutterFlow Integration

### Step 1: Store API Key in App State
Create an App State variable called `semaphoreApiKey` (String type).

### Step 2: Initialize with API Key
```dart
Future<String> initializeSchedulerSms(String apiKey) async {
  final scheduler = SchedulerSmsWebSemaphore();
  await scheduler.initialize(apiKey: apiKey);
  return 'Initialized successfully';
}
```

### Step 3: Call from UI
When your app starts, call the initialization function with the API key from App State or user input.

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for development and testing
3. **Implement proper access controls** in production
4. **Rotate API keys regularly**
5. **Monitor API usage** for suspicious activity

## Breaking Changes

- `SemaphoreConfig.apiKey` has been removed
- `SchedulerSmsWebSemaphore.initialize()` now requires `apiKey` parameter
- `initializeSchedulerSmsSemaphore()` in FlutterFlow custom actions now requires `apiKey` parameter

## Benefits

- ✅ API keys are no longer exposed in public repositories
- ✅ Each user can use their own API key
- ✅ Better security and compliance
- ✅ Easier to manage multiple environments (dev, staging, production)

## Questions?

If you have questions about this update, please open an issue on GitHub.
