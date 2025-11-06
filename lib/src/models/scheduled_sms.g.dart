// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_sms.dart';

ScheduledSMS _$ScheduledSMSFromJson(Map<String, dynamic> json) {
  final statusValue = json['status'];
  final statusString = statusValue is String
      ? statusValue
      : statusValue?.toString() ?? 'pending';

  final smsStatus = SmsStatus.values.firstWhere(
    (e) => e.toString().split('.').last == statusString,
    orElse: () => SmsStatus.pending,
  );

  return ScheduledSMS(
    id: json['id'] as String,
    customerId: json['customerId'] as String?,
    customerName: json['customerName'] as String?,
    recipient: json['recipient'] as String,
    message: json['message'] as String,
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    active: json['active'] as bool? ?? true,
    status: smsStatus,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
    sentAt: json['sentAt'] == null
        ? null
        : DateTime.parse(json['sentAt'] as String),
    errorMessage: json['errorMessage'] as String?,
    retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        const <String>[],
    priority: (json['priority'] as num?)?.toInt() ?? 3,
  );
}

Map<String, dynamic> _$ScheduledSMSToJson(ScheduledSMS instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'recipient': instance.recipient,
      'message': instance.message,
      'scheduledDate': instance.scheduledDate.toIso8601String(),
      'active': instance.active,
      'status': instance.status.toString().split('.').last,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'retryCount': instance.retryCount,
      'tags': instance.tags,
      'priority': instance.priority,
    };
