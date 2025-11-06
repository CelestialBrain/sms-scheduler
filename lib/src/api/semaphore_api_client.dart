import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for Semaphore SMS API
/// 
/// Semaphore is a Philippine-based SMS service provider with affordable rates
/// and reliable delivery for local numbers.
class SemaphoreApiClient {
  final String apiKey;
  final http.Client _client;

  /// Base URL for Semaphore API v4
  static const String baseUrl = 'https://api.semaphore.co/api/v4';

  SemaphoreApiClient({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Send a single SMS message
  /// 
  /// [number] - Recipient's mobile number (Philippine format, e.g., 09998887777)
  /// [message] - Message content (automatically split if over 160 characters)
  /// [senderName] - Optional sender name (defaults to "SEMAPHORE")
  /// 
  /// Returns a [SemaphoreSmsResponse] with message details
  Future<SemaphoreSmsResponse> sendMessage({
    required String number,
    required String message,
    String? senderName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'apikey': apiKey,
        'number': number,
        'message': message,
        if (senderName != null) 'sendername': senderName,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // API returns an array, get the first message
      if (data is List && data.isNotEmpty) {
        return SemaphoreSmsResponse.fromJson(data[0] as Map<String, dynamic>);
      } else if (data is Map) {
        return SemaphoreSmsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw SemaphoreApiException(
          'Unexpected response format',
          response.body,
        );
      }
    } else {
      throw SemaphoreApiException(
        'Failed to send message: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Send bulk SMS messages to multiple recipients
  /// 
  /// [numbers] - List of recipient mobile numbers (up to 1000)
  /// [message] - Message content
  /// [senderName] - Optional sender name
  /// 
  /// Returns a list of [SemaphoreSmsResponse] for each recipient
  Future<List<SemaphoreSmsResponse>> sendBulkMessages({
    required List<String> numbers,
    required String message,
    String? senderName,
  }) async {
    if (numbers.isEmpty) {
      throw ArgumentError('At least one number is required');
    }

    if (numbers.length > 1000) {
      throw ArgumentError('Maximum 1000 numbers allowed per request');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'apikey': apiKey,
        'number': numbers.join(','),
        'message': message,
        if (senderName != null) 'sendername': senderName,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List) {
        return data
            .map((item) => SemaphoreSmsResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw SemaphoreApiException(
          'Unexpected response format',
          response.body,
        );
      }
    } else {
      throw SemaphoreApiException(
        'Failed to send bulk messages: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Send a priority SMS message (bypasses queue, 2 credits per SMS)
  /// 
  /// Priority messages are sent immediately and are ideal for time-sensitive notifications
  Future<SemaphoreSmsResponse> sendPriorityMessage({
    required String number,
    required String message,
    String? senderName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/priority'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'apikey': apiKey,
        'number': number,
        'message': message,
        if (senderName != null) 'sendername': senderName,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List && data.isNotEmpty) {
        return SemaphoreSmsResponse.fromJson(data[0] as Map<String, dynamic>);
      } else if (data is Map) {
        return SemaphoreSmsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw SemaphoreApiException(
          'Unexpected response format',
          response.body,
        );
      }
    } else {
      throw SemaphoreApiException(
        'Failed to send priority message: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Send an OTP message (2 credits per SMS)
  /// 
  /// [number] - Recipient's mobile number
  /// [message] - Message template with {otp} placeholder
  /// [code] - Optional custom OTP code (auto-generated if not provided)
  Future<SemaphoreOtpResponse> sendOtpMessage({
    required String number,
    required String message,
    String? senderName,
    String? code,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/otp'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'apikey': apiKey,
        'number': number,
        'message': message,
        if (senderName != null) 'sendername': senderName,
        if (code != null) 'code': code,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List && data.isNotEmpty) {
        return SemaphoreOtpResponse.fromJson(data[0] as Map<String, dynamic>);
      } else if (data is Map) {
        return SemaphoreOtpResponse.fromJson(data as Map<String, dynamic>);
      } else {
        throw SemaphoreApiException(
          'Unexpected response format',
          response.body,
        );
      }
    } else {
      throw SemaphoreApiException(
        'Failed to send OTP message: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Retrieve account information
  Future<SemaphoreAccount> getAccount() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/account?apikey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return SemaphoreAccount.fromJson(data);
    } else {
      throw SemaphoreApiException(
        'Failed to get account: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Retrieve a message by ID
  Future<SemaphoreSmsResponse> getMessage(int messageId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/messages/$messageId?apikey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return SemaphoreSmsResponse.fromJson(data);
    } else {
      throw SemaphoreApiException(
        'Failed to get message: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}

/// Response from Semaphore SMS API
class SemaphoreSmsResponse {
  final int messageId;
  final int userId;
  final String user;
  final int accountId;
  final String account;
  final String recipient;
  final String message;
  final String senderName;
  final String network;
  final String status;
  final String type;
  final String source;
  final String createdAt;
  final String updatedAt;

  SemaphoreSmsResponse({
    required this.messageId,
    required this.userId,
    required this.user,
    required this.accountId,
    required this.account,
    required this.recipient,
    required this.message,
    required this.senderName,
    required this.network,
    required this.status,
    required this.type,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SemaphoreSmsResponse.fromJson(Map<String, dynamic> json) {
    return SemaphoreSmsResponse(
      messageId: json['message_id'] as int,
      userId: json['user_id'] as int,
      user: json['user'] as String,
      accountId: json['account_id'] as int,
      account: json['account'] as String,
      recipient: json['recipient'] as String,
      message: json['message'] as String,
      senderName: json['sender_name'] as String,
      network: json['network'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'user_id': userId,
      'user': user,
      'account_id': accountId,
      'account': account,
      'recipient': recipient,
      'message': message,
      'sender_name': senderName,
      'network': network,
      'status': status,
      'type': type,
      'source': source,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// Response from Semaphore OTP API
class SemaphoreOtpResponse extends SemaphoreSmsResponse {
  final String code;

  SemaphoreOtpResponse({
    required super.messageId,
    required super.userId,
    required super.user,
    required super.accountId,
    required super.account,
    required super.recipient,
    required super.message,
    required super.senderName,
    required super.network,
    required super.status,
    required super.type,
    required super.source,
    required super.createdAt,
    required super.updatedAt,
    required this.code,
  });

  factory SemaphoreOtpResponse.fromJson(Map<String, dynamic> json) {
    return SemaphoreOtpResponse(
      messageId: json['message_id'] as int,
      userId: json['user_id'] as int,
      user: json['user'] as String,
      accountId: json['account_id'] as int,
      account: json['account'] as String,
      recipient: json['recipient'] as String,
      message: json['message'] as String,
      senderName: json['sender_name'] as String,
      network: json['network'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      code: json['code'].toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['code'] = code;
    return map;
  }
}

/// Semaphore account information
class SemaphoreAccount {
  final int accountId;
  final String accountName;
  final String status;
  final double creditBalance;

  SemaphoreAccount({
    required this.accountId,
    required this.accountName,
    required this.status,
    required this.creditBalance,
  });

  factory SemaphoreAccount.fromJson(Map<String, dynamic> json) {
    return SemaphoreAccount(
      accountId: json['account_id'] as int,
      accountName: json['account_name'] as String,
      status: json['status'] as String,
      creditBalance: (json['credit_balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'account_name': accountName,
      'status': status,
      'credit_balance': creditBalance,
    };
  }
}

/// Exception thrown by Semaphore API
class SemaphoreApiException implements Exception {
  final String message;
  final String? responseBody;

  SemaphoreApiException(this.message, [this.responseBody]);

  @override
  String toString() {
    if (responseBody != null) {
      return 'SemaphoreApiException: $message\nResponse: $responseBody';
    }
    return 'SemaphoreApiException: $message';
  }
}
