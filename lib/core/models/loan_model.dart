import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final String userId;
  final double monthlySalary;
  final String salaryProofUrl;
  final String consentUrl;
  final int durationMonths;
  final String reason;
  final double loanableAmount;
  final String status;
  final DateTime? createdAt;
  final DateTime? approvedAt; // ← NEW FIELD ADDED
  final String? adminComment; // ← NEW FIELD ADDED
  final String? approvedBy; // ← NEW FIELD ADDED

  LoanModel({
    required this.id,
    required this.userId,
    required this.monthlySalary,
    required this.salaryProofUrl,
    required this.consentUrl,
    required this.durationMonths,
    required this.reason,
    required this.loanableAmount,
    required this.status,
    this.createdAt,
    this.approvedAt, // ← NEW FIELD
    this.adminComment, // ← NEW FIELD
    this.approvedBy, // ← NEW FIELD
  });

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map["id"] ?? "",
      userId: map["userId"] ?? "",
      monthlySalary: (map["monthlySalary"] ?? 0).toDouble(),
      salaryProofUrl: map["salaryProofUrl"] ?? "",
      consentUrl: map["consentUrl"] ?? "",
      durationMonths: map["durationMonths"] ?? 0,
      reason: map["reason"] ?? "",
      loanableAmount: (map["loanableAmount"] ?? 0).toDouble(),
      status: map["status"] ?? "pending",
      createdAt: (map["createdAt"] is Timestamp)
          ? (map["createdAt"] as Timestamp).toDate()
          : null,
      approvedAt:
          (map["approvedAt"] is Timestamp) // ← NEW FIELD MAPPING
          ? (map["approvedAt"] as Timestamp).toDate()
          : null,
      adminComment: map["adminComment"], // ← NEW FIELD MAPPING
      approvedBy: map["approvedBy"], // ← NEW FIELD MAPPING
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "monthlySalary": monthlySalary,
      "salaryProofUrl": salaryProofUrl,
      "consentUrl": consentUrl,
      "durationMonths": durationMonths,
      "reason": reason,
      "loanableAmount": loanableAmount,
      "status": status,
      "createdAt": createdAt ?? FieldValue.serverTimestamp(),
      "approvedAt": approvedAt, // ← NEW FIELD IN MAP
      "adminComment": adminComment, // ← NEW FIELD IN MAP
      "approvedBy": approvedBy, // ← NEW FIELD IN MAP
    };
  }
}
