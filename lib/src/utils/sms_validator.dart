/// Utility class for validating SMS-related data
class SmsValidator {
  /// Validate a Philippine mobile number
  static bool isValidPhilippineMobileNumber(String number) {
    // Remove any non-digit characters
    final cleaned = number.replaceAll(RegExp(r'\D'), '');

    // Check for valid Philippine mobile number formats
    // 09xxxxxxxxx (11 digits)
    // 639xxxxxxxxx (12 digits)
    // 9xxxxxxxxx (10 digits)
    
    if (cleaned.length == 11 && cleaned.startsWith('09')) {
      return _isValidPrefix(cleaned.substring(0, 4));
    } else if (cleaned.length == 12 && cleaned.startsWith('639')) {
      return _isValidPrefix('0${cleaned.substring(2, 5)}');
    } else if (cleaned.length == 10 && cleaned.startsWith('9')) {
      return _isValidPrefix('0${cleaned.substring(0, 3)}');
    }

    return false;
  }

  /// Check if the prefix is valid for Philippine networks
  static bool _isValidPrefix(String prefix) {
    // Globe/TM prefixes
    final globePrefixes = [
      '0905', '0906', '0915', '0916', '0917', '0926', '0927',
      '0935', '0936', '0937', '0945', '0953', '0954', '0955',
      '0956', '0965', '0966', '0967', '0975', '0976', '0977',
      '0978', '0979', '0995', '0996', '0997'
    ];

    // Smart/TNT/Sun prefixes
    final smartPrefixes = [
      '0907', '0908', '0909', '0910', '0911', '0912', '0913',
      '0914', '0918', '0919', '0920', '0921', '0928', '0929',
      '0930', '0938', '0939', '0946', '0947', '0948', '0949',
      '0950', '0951', '0961', '0963', '0964', '0968', '0969',
      '0970', '0971', '0980', '0981', '0989', '0992', '0993',
      '0994', '0998', '0999'
    ];

    // DITO prefixes
    final ditoPrefixes = [
      '0895', '0896', '0897', '0898', '0991'
    ];

    return globePrefixes.contains(prefix) ||
        smartPrefixes.contains(prefix) ||
        ditoPrefixes.contains(prefix);
  }

  /// Get the network provider from a Philippine mobile number
  static String? getNetworkProvider(String number) {
    if (!isValidPhilippineMobileNumber(number)) {
      return null;
    }

    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    String prefix;

    if (cleaned.length == 11 && cleaned.startsWith('09')) {
      prefix = cleaned.substring(0, 4);
    } else if (cleaned.length == 12 && cleaned.startsWith('639')) {
      prefix = '0${cleaned.substring(2, 5)}';
    } else if (cleaned.length == 10 && cleaned.startsWith('9')) {
      prefix = '0${cleaned.substring(0, 3)}';
    } else {
      return null;
    }

    // Globe/TM prefixes
    if ([
      '0905', '0906', '0915', '0916', '0917', '0926', '0927',
      '0935', '0936', '0937', '0945', '0953', '0954', '0955',
      '0956', '0965', '0966', '0967', '0975', '0976', '0977',
      '0978', '0979', '0995', '0996', '0997'
    ].contains(prefix)) {
      return 'Globe';
    }

    // Smart/TNT/Sun prefixes
    if ([
      '0907', '0908', '0909', '0910', '0911', '0912', '0913',
      '0914', '0918', '0919', '0920', '0921', '0928', '0929',
      '0930', '0938', '0939', '0946', '0947', '0948', '0949',
      '0950', '0951', '0961', '0963', '0964', '0968', '0969',
      '0970', '0971', '0980', '0981', '0989', '0992', '0993',
      '0994', '0998', '0999'
    ].contains(prefix)) {
      return 'Smart';
    }

    // DITO prefixes
    if (['0895', '0896', '0897', '0898', '0991'].contains(prefix)) {
      return 'DITO';
    }

    return null;
  }

  /// Validate SMS message length
  static bool isValidMessageLength(String message, {int maxLength = 160}) {
    return message.isNotEmpty && message.length <= maxLength;
  }

  /// Get the number of SMS segments for a message
  static int getMessageSegments(String message) {
    if (message.isEmpty) return 0;

    // Standard SMS is 160 characters
    // Multi-part SMS uses 153 characters per segment (7 chars for header)
    if (message.length <= 160) {
      return 1;
    } else {
      return (message.length / 153).ceil();
    }
  }

  /// Validate scheduled date
  static bool isValidScheduledDate(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Format Philippine mobile number to standard format (09xxxxxxxxx)
  static String formatPhilippineMobileNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('63') && cleaned.length == 12) {
      return '0${cleaned.substring(2)}';
    } else if (cleaned.startsWith('9') && cleaned.length == 10) {
      return '0$cleaned';
    } else if (cleaned.startsWith('09') && cleaned.length == 11) {
      return cleaned;
    }

    throw ArgumentError('Invalid Philippine mobile number format: $number');
  }

  /// Format mobile number to international format (+63xxxxxxxxxx)
  static String formatToInternational(String number) {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('63') && cleaned.length == 12) {
      return '+$cleaned';
    } else if (cleaned.startsWith('09') && cleaned.length == 11) {
      return '+63${cleaned.substring(1)}';
    } else if (cleaned.startsWith('9') && cleaned.length == 10) {
      return '+63$cleaned';
    }

    throw ArgumentError('Invalid Philippine mobile number format: $number');
  }
}
