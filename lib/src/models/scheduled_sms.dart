import 'package:json_annotation/json_annotation.dart';

import 'sms_status.dart';

part 'scheduled_sms.g.dart';

/// Represents a scheduled SMS message
@JsonSerializable()
class ScheduledSMS {
  /// Unique identifier for the scheduled SMS
  final String id;

  /// Customer ID (reference to Customer table)
  final String? customerId;

  /// Customer name (denormalized for quick access)
  final String? customerName;

  /// Recipient phone number (with country code)
  final String recipient;

  /// Message content
  final String message;

  /// Scheduled date and time for sending
  final DateTime scheduledDate;

  /// Whether this scheduled SMS is active (enabled)
  final bool active;

  /// Current status of the SMS
  final SmsStatus status;

  /// Timestamp when the SMS was created
  final DateTime createdAt;

  /// Timestamp when the SMS was last updated
  final DateTime? updatedAt;

  /// Timestamp when the SMS was actually sent
  final DateTime? sentAt;

  /// Error message if sending failed
  final String? errorMessage;

  /// Number of retry attempts
  final int retryCount;

  /// Tags for categorizing this SMS
  final List<String> tags;

  /// Priority level (1-5, where 5 is highest)
  final int priority;

  ScheduledSMS({
    required this.id,
    this.customerId,
    this.customerName,
    required this.recipient,
    required this.message,
    required this.scheduledDate,
    this.active = true,
    this.status = SmsStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.sentAt,
    this.errorMessage,
    this.retryCount = 0,
    this.tags = const [],
    this.priority = 3,
  });

  /// Create a copy of this ScheduledSMS with updated fields
  ScheduledSMS copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? recipient,
    String? message,
    DateTime? scheduledDate,
    bool? active,
    SmsStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    String? errorMessage,
    int? retryCount,
    List<String>? tags,
    int? priority,
  }) {
    return ScheduledSMS(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      recipient: recipient ?? this.recipient,
      message: message ?? this.message,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      active: active ?? this.active,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ScheduledSMSToJson(this);

  /// Create from JSON
  factory ScheduledSMS.fromJson(Map<String, dynamic> json) =>
      _$ScheduledSMSFromJson(json);

  /// Convert to database map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'recipient': recipient,
      'message': message,
      'scheduledDate': scheduledDate.toIso8601String(),
      'active': active ? 1 : 0,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'tags': tags.join(','),
      'priority': priority,
    };

    if (customerId != null) {
      map['customerId'] = customerId;
    }

    if (customerName != null) {
      map['customerName'] = customerName;
    }

    return map;
  }

  /// Create from database map
  factory ScheduledSMS.fromMap(Map<String, dynamic> map) {
    final statusValue = map['status']?.toString() ?? 'pending';

    return ScheduledSMS(
      id: map['id'] as String,
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String?,
      recipient: map['recipient'] as String,
      message: map['message'] as String,
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
      active: map['active'] is int
          ? (map['active'] as int) == 1
          : (map['active'] as bool? ?? true),
      status: SmsStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusValue,
        orElse: () => SmsStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      sentAt: map['sentAt'] != null
          ? DateTime.parse(map['sentAt'] as String)
          : null,
      errorMessage: map['errorMessage'] as String?,
      retryCount: map['retryCount'] is int
          ? map['retryCount'] as int
          : int.tryParse(map['retryCount']?.toString() ?? '') ?? 0,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : <String>[],
      priority: map['priority'] is int
          ? map['priority'] as int
          : int.tryParse(map['priority']?.toString() ?? '') ?? 3,
    );
  }

  @override
  String toString() {
    return 'ScheduledSMS(id: $id, customer: $customerName, recipient: $recipient, scheduledDate: $scheduledDate, active: $active, status: $status)';
  }
}
