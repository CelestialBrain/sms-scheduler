import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

/// Represents a customer with contact information
@JsonSerializable()
class Customer {
  /// Unique identifier for the customer
  final String id;

  /// Customer's name
  final String name;

  /// Customer's phone number (with country code)
  final String phoneNumber;

  /// Customer's email address (optional)
  final String? email;

  /// Additional notes about the customer
  final String? notes;

  /// Tags for categorizing customers
  final List<String> tags;

  /// Custom metadata as key-value pairs
  final Map<String, String> metadata;

  /// Timestamp when the customer was created
  final DateTime createdAt;

  /// Timestamp when the customer was last updated
  final DateTime? updatedAt;

  /// Whether this customer is active
  final bool active;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.notes,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
    this.active = true,
  });

  /// Create a copy of this Customer with updated fields
  Customer copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? notes,
    List<String>? tags,
    Map<String, String>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  /// Create from JSON
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'notes': notes,
      'tags': tags.join(','),
      'metadata': metadata.entries.map((e) => '${e.key}:${e.value}').join('|'),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'active': active ? 1 : 0,
    };
  }

  /// Create from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      metadata: map['metadata'] != null && (map['metadata'] as String).isNotEmpty
          ? Map.fromEntries(
              (map['metadata'] as String).split('|').map((entry) {
                final parts = entry.split(':');
                return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
              }),
            )
          : {},
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      active: (map['active'] as int) == 1,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phoneNumber: $phoneNumber, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
