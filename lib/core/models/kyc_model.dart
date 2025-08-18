import 'package:cloud_firestore/cloud_firestore.dart';

class KYCModel {
  final String uid;
  final String fullName;
  final String phone;
  final String dateOfBirth;
  final String citizenshipNumber;
  final String citizenshipPhotoUrl;
  final bool verified;
  final DateTime? submittedAt;

  KYCModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.dateOfBirth,
    required this.citizenshipNumber,
    required this.citizenshipPhotoUrl,
    required this.verified,
    this.submittedAt,
  });

  factory KYCModel.fromMap(Map<String, dynamic> map) {
    return KYCModel(
      uid: map["uid"] ?? "",
      fullName: map["fullName"] ?? "",
      phone: map["phone"] ?? "",
      dateOfBirth: map["dateOfBirth"] ?? "",
      citizenshipNumber: map["citizenshipNumber"] ?? "",
      citizenshipPhotoUrl: map["citizenshipPhotoUrl"] ?? "",
      verified: map["verified"] ?? false,
      submittedAt: (map["submittedAt"] is Timestamp)
          ? (map["submittedAt"] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullName": fullName,
      "phone": phone,
      "dateOfBirth": dateOfBirth,
      "citizenshipNumber": citizenshipNumber,
      "citizenshipPhotoUrl": citizenshipPhotoUrl,
      "verified": verified,
      "submittedAt": FieldValue.serverTimestamp(),
    };
  }
}
