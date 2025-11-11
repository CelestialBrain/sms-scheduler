/// FlutterFlow Custom Actions for SchedulerSMS with Semaphore API
/// 
/// Copy these custom actions into your FlutterFlow project to use the SchedulerSMS.
/// Make sure to add the schedulersms package to your project dependencies first.

import 'package:schedulersms/schedulersms.dart';

// ============================================================================
// INITIALIZATION
// ============================================================================

/// Initialize the SchedulerSMS with Semaphore API for web
/// 
/// Call this action when your app starts (e.g., in the initial page's "On Page Load" action)
/// 
/// Parameters:
/// - apiKey: Your Semaphore API key (get it from https://semaphore.co/)
/// - senderName: Optional custom sender name (defaults to "SEMAPHORE")
Future<String> initializeSchedulerSmsSemaphore(
  String apiKey, {
  String? senderName,
}) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.initialize(
      apiKey: apiKey,
      senderName: senderName,
    );
    
    // Get account info to verify connection
    final account = await scheduler.getAccountInfo();
    
    return 'Initialized successfully! Balance: ${account.creditBalance} credits';
  } catch (e) {
    return 'Error: $e';
  }
}

// ============================================================================
// CUSTOMER MANAGEMENT
// ============================================================================

/// Create a new customer
/// 
/// Parameters:
/// - name: Customer's full name
/// - phoneNumber: Philippine mobile number (e.g., 09171234567)
/// - email: Optional email address
Future<String> createCustomer(
  String name,
  String phoneNumber,
  String? email,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    final customer = await scheduler.createCustomer(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );
    
    return customer.id;
  } catch (e) {
    throw Exception('Failed to create customer: $e');
  }
}

/// Get all customers
/// 
/// Returns a list of customer maps that can be displayed in a ListView
Future<List<dynamic>> getAllCustomers() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final customers = await scheduler.getAllCustomers();
    
    return customers.map((customer) => customer.toMap()).toList();
  } catch (e) {
    throw Exception('Failed to get customers: $e');
  }
}

/// Get a single customer by ID
Future<dynamic> getCustomer(String customerId) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final customer = await scheduler.getCustomer(customerId);
    
    if (customer == null) {
      throw Exception('Customer not found');
    }
    
    return customer.toMap();
  } catch (e) {
    throw Exception('Failed to get customer: $e');
  }
}

/// Search customers by name or phone number
Future<List<dynamic>> searchCustomers(String query) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final customers = await scheduler.searchCustomers(query);
    
    return customers.map((customer) => customer.toMap()).toList();
  } catch (e) {
    throw Exception('Failed to search customers: $e');
  }
}

/// Update a customer
Future<void> updateCustomer(
  String customerId,
  String? name,
  String? phoneNumber,
  String? email,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    await scheduler.updateCustomer(
      id: customerId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );
  } catch (e) {
    throw Exception('Failed to update customer: $e');
  }
}

/// Delete a customer
Future<void> deleteCustomer(String customerId) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.deleteCustomer(customerId);
  } catch (e) {
    throw Exception('Failed to delete customer: $e');
  }
}

// ============================================================================
// SMS SCHEDULING
// ============================================================================

/// Schedule an SMS for a customer
/// 
/// Parameters:
/// - customerId: The ID of the customer to send to
/// - message: The message content (max 160 characters for 1 credit)
/// - scheduledDate: When to send the message
/// 
/// Returns the SMS ID
Future<String> scheduleSmsForCustomer(
  String customerId,
  String message,
  DateTime scheduledDate,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    // Get the customer
    final customer = await scheduler.getCustomer(customerId);
    
    if (customer == null) {
      throw Exception('Customer not found');
    }
    
    // Schedule the SMS
    final sms = await scheduler.scheduleSms(
      customer: customer,
      message: message,
      scheduledDate: scheduledDate,
    );
    
    return sms.id;
  } catch (e) {
    throw Exception('Failed to schedule SMS: $e');
  }
}

/// Schedule an SMS using phone number directly (without customer)
/// 
/// Parameters:
/// - phoneNumber: Philippine mobile number (e.g., 09171234567)
/// - message: The message content
/// - scheduledDate: When to send the message
Future<String> scheduleSmsDirectly(
  String phoneNumber,
  String message,
  DateTime scheduledDate,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    // Create a temporary customer or find existing one
    Customer? customer = await scheduler.getCustomerByPhone(phoneNumber);
    
    if (customer == null) {
      // Create a new customer with just the phone number
      customer = await scheduler.createCustomer(
        name: 'Customer $phoneNumber',
        phoneNumber: phoneNumber,
      );
    }
    
    // Schedule the SMS
    final sms = await scheduler.scheduleSms(
      customer: customer,
      message: message,
      scheduledDate: scheduledDate,
    );
    
    return sms.id;
  } catch (e) {
    throw Exception('Failed to schedule SMS: $e');
  }
}

/// Get all scheduled messages
Future<List<dynamic>> getAllScheduledMessages() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final messages = await scheduler.getAllScheduledSms();
    
    return messages.map((sms) => sms.toMap()).toList();
  } catch (e) {
    throw Exception('Failed to get scheduled messages: $e');
  }
}

/// Get scheduled messages for a specific customer
Future<List<dynamic>> getScheduledMessagesForCustomer(String customerId) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final messages = await scheduler.getScheduledSmsForCustomer(customerId);
    
    return messages.map((sms) => sms.toMap()).toList();
  } catch (e) {
    throw Exception('Failed to get customer messages: $e');
  }
}

/// Cancel a scheduled SMS
Future<void> cancelScheduledSms(String smsId) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.cancelScheduledSms(smsId);
  } catch (e) {
    throw Exception('Failed to cancel SMS: $e');
  }
}

/// Delete a scheduled SMS
Future<void> deleteScheduledSms(String smsId) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    await scheduler.deleteScheduledSms(smsId);
  } catch (e) {
    throw Exception('Failed to delete SMS: $e');
  }
}

/// Update a scheduled SMS
Future<void> updateScheduledSms(
  String smsId,
  String? message,
  DateTime? scheduledDate,
) async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    
    await scheduler.updateScheduledSms(
      id: smsId,
      message: message,
      scheduledDate: scheduledDate,
    );
  } catch (e) {
    throw Exception('Failed to update SMS: $e');
  }
}

// ============================================================================
// ACCOUNT INFORMATION
// ============================================================================

/// Get Semaphore account balance and information
/// 
/// Returns a map with account details including credit balance
Future<dynamic> getSemaphoreAccountInfo() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final account = await scheduler.getAccountInfo();
    
    return account.toJson();
  } catch (e) {
    throw Exception('Failed to get account info: $e');
  }
}

/// Get account credit balance only
Future<double> getAccountBalance() async {
  try {
    final scheduler = SchedulerSmsWebSemaphore();
    final account = await scheduler.getAccountInfo();
    
    return account.creditBalance;
  } catch (e) {
    throw Exception('Failed to get balance: $e');
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Format Philippine phone number
/// 
/// Converts various formats to standard format (e.g., 09171234567)
String formatPhilippineNumber(String phoneNumber) {
  // Remove all non-digit characters
  String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Handle different formats
  if (cleaned.startsWith('63')) {
    // +63 format -> convert to 0 format
    cleaned = '0${cleaned.substring(2)}';
  } else if (cleaned.startsWith('9') && cleaned.length == 10) {
    // Missing leading 0
    cleaned = '0$cleaned';
  }
  
  return cleaned;
}

/// Validate Philippine mobile number
bool isValidPhilippineNumber(String phoneNumber) {
  String cleaned = formatPhilippineNumber(phoneNumber);
  
  // Should be 11 digits starting with 09
  if (cleaned.length != 11) return false;
  if (!cleaned.startsWith('09')) return false;
  
  // Check if it's a valid network prefix
  List<String> validPrefixes = [
    '0905', '0906', '0915', '0916', '0917', '0926', '0927', '0935', '0936', '0945', // Globe
    '0813', '0907', '0908', '0909', '0910', '0912', '0918', '0919', '0920', '0921', '0928', '0929', '0930', '0938', '0939', '0946', '0947', '0948', '0949', '0950', '0951', // Smart
    '0895', '0896', '0897', '0898', '0991', '0992', '0993', '0994', // DITO
  ];
  
  return validPrefixes.any((prefix) => cleaned.startsWith(prefix));
}
