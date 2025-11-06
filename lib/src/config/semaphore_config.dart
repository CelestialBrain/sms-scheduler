/// Semaphore SMS API Configuration
/// 
/// This file contains the API key for Semaphore SMS service.
/// Keep this file secure and do not share it publicly.
class SemaphoreConfig {
  /// Semaphore API Key
  /// 
  /// This key is used to authenticate with the Semaphore SMS API.
  /// The API key is stored in this private repository for security.
  static const String apiKey = '1fd72138299086e8fc5656a9826ac7e9';

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
