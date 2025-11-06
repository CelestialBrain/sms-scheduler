import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for Philippine load reseller APIs
class LoadApiClient {
  final String baseUrl;
  final String uid;
  final String password;
  final String companyPrefix;
  final http.Client _client;

  LoadApiClient({
    required this.baseUrl,
    required this.uid,
    required this.password,
    required this.companyPrefix,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Get available load products
  Future<List<LoadProduct>> getProducts() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List;
      return products
          .map((p) => LoadProduct.fromJson(p as Map<String, dynamic>))
          .toList();
    } else {
      throw LoadApiException(
        'Failed to get products: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Purchase prepaid load
  Future<LoadPurchaseResult> purchaseLoad({
    required String productCode,
    required String mobileNumber,
  }) async {
    // Generate unique RRN (Retrieval Reference Number)
    final rrn = _generateRRN();

    final response = await _client.post(
      Uri.parse('$baseUrl/sell'),
      headers: _getHeaders(),
      body: json.encode({
        'uid': uid,
        'password': password,
        'pcode': productCode,
        'to': _formatMobileNumber(mobileNumber),
        'rrn': rrn,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return LoadPurchaseResult.fromJson(data, rrn);
    } else {
      throw LoadApiException(
        'Failed to purchase load: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Inquire about a transaction
  Future<LoadTransactionStatus> inquireTransaction({
    required String rrn,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/inquire'),
      headers: _getHeaders(),
      body: json.encode({
        'uid': uid,
        'password': password,
        'rrn': rrn,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return LoadTransactionStatus.fromJson(data);
    } else {
      throw LoadApiException(
        'Failed to inquire transaction: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Get account balance
  Future<double> getBalance() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/balance'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['balance'] as num).toDouble();
    } else {
      throw LoadApiException(
        'Failed to get balance: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Format mobile number to Philippine format
  String _formatMobileNumber(String number) {
    // Remove any non-digit characters
    final cleaned = number.replaceAll(RegExp(r'\D'), '');

    // Convert to 11-digit format (09xxxxxxxxx)
    if (cleaned.startsWith('63')) {
      return '0${cleaned.substring(2)}';
    } else if (cleaned.startsWith('9') && cleaned.length == 10) {
      return '0$cleaned';
    } else if (cleaned.startsWith('09') && cleaned.length == 11) {
      return cleaned;
    }

    throw ArgumentError('Invalid Philippine mobile number format: $number');
  }

  /// Generate unique RRN
  String _generateRRN() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return '$companyPrefix$random';
  }

  /// Get common headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('$uid:$password'))}',
    };
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}

/// Represents a load product
class LoadProduct {
  final String code;
  final String name;
  final String network; // Globe, Smart, DITO, etc.
  final double price;
  final String currency;
  final String? description;

  LoadProduct({
    required this.code,
    required this.name,
    required this.network,
    required this.price,
    required this.currency,
    this.description,
  });

  factory LoadProduct.fromJson(Map<String, dynamic> json) {
    return LoadProduct(
      code: json['code'] as String,
      name: json['name'] as String,
      network: json['network'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'network': network,
      'price': price,
      'currency': currency,
      'description': description,
    };
  }
}

/// Result of a load purchase
class LoadPurchaseResult {
  final String rrn;
  final String status;
  final String message;
  final String? transactionId;
  final DateTime timestamp;

  LoadPurchaseResult({
    required this.rrn,
    required this.status,
    required this.message,
    this.transactionId,
    required this.timestamp,
  });

  factory LoadPurchaseResult.fromJson(Map<String, dynamic> json, String rrn) {
    return LoadPurchaseResult(
      rrn: rrn,
      status: json['status'] as String,
      message: json['message'] as String,
      transactionId: json['transaction_id'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rrn': rrn,
      'status': status,
      'message': message,
      'transaction_id': transactionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isSuccessful => status.toLowerCase() == 'success';
}

/// Status of a load transaction
class LoadTransactionStatus {
  final String rrn;
  final String status;
  final String message;
  final String? productCode;
  final String? mobileNumber;
  final double? amount;
  final DateTime? timestamp;

  LoadTransactionStatus({
    required this.rrn,
    required this.status,
    required this.message,
    this.productCode,
    this.mobileNumber,
    this.amount,
    this.timestamp,
  });

  factory LoadTransactionStatus.fromJson(Map<String, dynamic> json) {
    return LoadTransactionStatus(
      rrn: json['rrn'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
      productCode: json['product_code'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rrn': rrn,
      'status': status,
      'message': message,
      'product_code': productCode,
      'mobile_number': mobileNumber,
      'amount': amount,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  bool get isSuccessful => status.toLowerCase() == 'success';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
}

/// Exception thrown by Load API
class LoadApiException implements Exception {
  final String message;
  final String? responseBody;

  LoadApiException(this.message, [this.responseBody]);

  @override
  String toString() {
    if (responseBody != null) {
      return 'LoadApiException: $message\nResponse: $responseBody';
    }
    return 'LoadApiException: $message';
  }
}
