/// Status of a scheduled SMS message
enum SmsStatus {
  /// SMS is waiting to be sent
  pending,

  /// SMS is currently being sent
  sending,

  /// SMS was sent successfully
  sent,

  /// SMS sending failed
  failed,

  /// SMS was cancelled by user
  cancelled,
}

/// Extension methods for SmsStatus
extension SmsStatusExtension on SmsStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case SmsStatus.pending:
        return 'Waiting to be sent';
      case SmsStatus.sending:
        return 'Sending...';
      case SmsStatus.sent:
        return 'Sent successfully';
      case SmsStatus.failed:
        return 'Failed to send';
      case SmsStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if the SMS is in a final state (sent, failed, or cancelled)
  bool get isFinal {
    return this == SmsStatus.sent ||
        this == SmsStatus.failed ||
        this == SmsStatus.cancelled;
  }

  /// Check if the SMS can be retried
  bool get canRetry {
    return this == SmsStatus.failed;
  }
}
