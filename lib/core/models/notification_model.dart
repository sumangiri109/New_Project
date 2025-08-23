// lib/core/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final bool broadcast;
  final String? sentBy;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.broadcast = false,
    this.sentBy,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map["id"] ?? "",
      userId: map["userId"] ?? "",
      title: map["title"] ?? "",
      message: map["message"] ?? "",
      type: map["type"] ?? "general",
      read: map["read"] ?? false,
      broadcast: map["broadcast"] ?? false,
      sentBy: map["sentBy"],
      createdAt: (map["createdAt"] is Timestamp)
          ? (map["createdAt"] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "title": title,
      "message": message,
      "type": type,
      "read": read,
      "broadcast": broadcast,
      "sentBy": sentBy,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? read,
    bool? broadcast,
    String? sentBy,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      broadcast: broadcast ?? this.broadcast,
      sentBy: sentBy ?? this.sentBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
