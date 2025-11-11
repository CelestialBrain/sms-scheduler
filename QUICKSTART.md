# Quick Start Guide

Get started with the SchedulerSMS package in 5 minutes!

## Step 1: Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  schedulersms: ^2.0.0
```

Run:
```bash
flutter pub get
```

## Step 2: Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

## Step 3: Initialize the Service

```dart
import 'package:schedulersms/schedulersms.dart';

final smsService = SchedulerSmsService();
await smsService.initialize();
```

## Step 4: Schedule Your First SMS

```dart
await smsService.scheduleSms(
  recipient: '+639171234567',
  message: 'Hello from SchedulerSMS!',
  scheduledDate: DateTime.now().add(Duration(minutes: 5)),
);
```

## Step 5: Listen for Updates

```dart
smsService.statusStream.listen((sms) {
  print('SMS status: ${sms.status.description}');
});
```

That's it! Your SMS will be sent automatically at the scheduled time.

## Next Steps

- Check out the [README.md](README.md) for detailed documentation
- See the [example app](example/lib/main.dart) for a complete implementation
- Read the [comprehensive guide](doc/comprehensive_guide.md) for eSIM and load API integration

## Common Issues

**SMS not sending?**
- Make sure permissions are granted
- Check the phone number format (+63xxxxxxxxxx)
- Verify device has network connectivity

**Background tasks not working?**
- Disable battery optimization for your app
- Check WorkManager initialization

Need help? File an issue on our GitHub repository!
