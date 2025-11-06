/// Semaphore SMS API Configuration
/// 
/// This file contains default configuration for Semaphore SMS service.
/// API keys should be provided at runtime through the initialize method
/// rather than being hardcoded in the repository.
class SemaphoreConfig {
  /// Default sender name for SMS messages
  /// 
  /// This will appear as the sender when recipients receive messages.
  /// You can override this when sending individual messages.
  static const String defaultSenderName = 'SEMAPHORE';

  /// Whether to use priority queue for messages
  /// 
  /// Priority messages bypass the regular queue and are sent immediately.
  /// This costs 2 credits per SMS instead of 1.
  static const bool usePriorityQueue = false;
}
