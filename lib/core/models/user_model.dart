import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastOnline;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    this.createdAt,
    this.lastOnline,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      email: map["email"] ?? "",
      displayName: map["displayName"] ?? "",
      photoUrl: map["photoUrl"] ?? "",
      role: map["role"] ?? "user",
      createdAt: (map["createdAt"] is Timestamp)
          ? (map["createdAt"] as Timestamp).toDate()
          : null,
      lastOnline: (map["lastOnline"] is Timestamp)
          ? (map["lastOnline"] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "displayName": displayName,
      "photoUrl": photoUrl,
      "role": role,
      "createdAt": createdAt,
      "lastOnline": lastOnline,
    };
  }
}
