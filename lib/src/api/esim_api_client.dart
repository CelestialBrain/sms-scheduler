import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for eSIM provider APIs (e.g., Airalo, eSIM Access)
class ESimApiClient {
  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  ESimApiClient({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Get available eSIM packages for a country
  Future<List<ESimPackage>> getPackages({
    required String countryCode,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/packages?country=$countryCode'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final packages = data['packages'] as List;
      return packages
          .map((p) => ESimPackage.fromJson(p as Map<String, dynamic>))
          .toList();
    } else {
      throw ESimApiException(
        'Failed to get packages: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Purchase an eSIM package
  Future<ESimPurchaseResult> purchasePackage({
    required String packageId,
    required String email,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/purchase'),
      headers: _getHeaders(),
      body: json.encode({
        'package_id': packageId,
        'email': email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ESimPurchaseResult.fromJson(data);
    } else {
      throw ESimApiException(
        'Failed to purchase package: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Get eSIM details by order ID
  Future<ESimDetails> getESimDetails({
    required String orderId,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ESimDetails.fromJson(data);
    } else {
      throw ESimApiException(
        'Failed to get eSIM details: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Get common headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}

/// Represents an eSIM package
class ESimPackage {
  final String id;
  final String name;
  final String countryCode;
  final String countryName;
  final double price;
  final String currency;
  final int dataAmount; // in MB
  final int validityDays;
  final String? description;

  ESimPackage({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.price,
    required this.currency,
    required this.dataAmount,
    required this.validityDays,
    this.description,
  });

  factory ESimPackage.fromJson(Map<String, dynamic> json) {
    return ESimPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['country_code'] as String,
      countryName: json['country_name'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      dataAmount: json['data_amount'] as int,
      validityDays: json['validity_days'] as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_code': countryCode,
      'country_name': countryName,
      'price': price,
      'currency': currency,
      'data_amount': dataAmount,
      'validity_days': validityDays,
      'description': description,
    };
  }
}

/// Result of an eSIM purchase
class ESimPurchaseResult {
  final String orderId;
  final String packageId;
  final String status;
  final String? qrCode;
  final String? activationCode;
  final String? iccid;

  ESimPurchaseResult({
    required this.orderId,
    required this.packageId,
    required this.status,
    this.qrCode,
    this.activationCode,
    this.iccid,
  });

  factory ESimPurchaseResult.fromJson(Map<String, dynamic> json) {
    return ESimPurchaseResult(
      orderId: json['order_id'] as String,
      packageId: json['package_id'] as String,
      status: json['status'] as String,
      qrCode: json['qr_code'] as String?,
      activationCode: json['activation_code'] as String?,
      iccid: json['iccid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'package_id': packageId,
      'status': status,
      'qr_code': qrCode,
      'activation_code': activationCode,
      'iccid': iccid,
    };
  }
}

/// Detailed eSIM information
class ESimDetails {
  final String orderId;
  final String packageId;
  final String status;
  final String qrCode;
  final String? activationCode;
  final String? iccid;
  final DateTime? expiryDate;
  final int? remainingData; // in MB

  ESimDetails({
    required this.orderId,
    required this.packageId,
    required this.status,
    required this.qrCode,
    this.activationCode,
    this.iccid,
    this.expiryDate,
    this.remainingData,
  });

  factory ESimDetails.fromJson(Map<String, dynamic> json) {
    return ESimDetails(
      orderId: json['order_id'] as String,
      packageId: json['package_id'] as String,
      status: json['status'] as String,
      qrCode: json['qr_code'] as String,
      activationCode: json['activation_code'] as String?,
      iccid: json['iccid'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      remainingData: json['remaining_data'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'package_id': packageId,
      'status': status,
      'qr_code': qrCode,
      'activation_code': activationCode,
      'iccid': iccid,
      'expiry_date': expiryDate?.toIso8601String(),
      'remaining_data': remainingData,
    };
  }
}

/// Exception thrown by eSIM API
class ESimApiException implements Exception {
  final String message;
  final String? responseBody;

  ESimApiException(this.message, [this.responseBody]);

  @override
  String toString() {
    if (responseBody != null) {
      return 'ESimApiException: $message\nResponse: $responseBody';
    }
    return 'ESimApiException: $message';
  }
}
