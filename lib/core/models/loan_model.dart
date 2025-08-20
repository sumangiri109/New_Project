import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final String userId;
  final double monthlySalary;
  final String salaryProofUrl;
  final String consentUrl; // Added consent URL field
  final int durationMonths;
  final String reason;
  final double loanableAmount;
  final String status;
  final DateTime? createdAt;

  LoanModel({
    required this.id,
    required this.userId,
    required this.monthlySalary,
    required this.salaryProofUrl,
    required this.consentUrl, // Added to constructor
    required this.durationMonths,
    required this.reason,
    required this.loanableAmount,
    required this.status,
    this.createdAt,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map["id"] ?? "",
      userId: map["userId"] ?? "",
      monthlySalary: (map["monthlySalary"] ?? 0).toDouble(),
      salaryProofUrl: map["salaryProofUrl"] ?? "",
      consentUrl: map["consentUrl"] ?? "", // Added consent URL mapping
      durationMonths: map["durationMonths"] ?? 0,
      reason: map["reason"] ?? "",
      loanableAmount: (map["loanableAmount"] ?? 0).toDouble(),
      status: map["status"] ?? "pending",
      createdAt: (map["createdAt"] is Timestamp)
          ? (map["createdAt"] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "monthlySalary": monthlySalary,
      "salaryProofUrl": salaryProofUrl,
      "consentUrl": consentUrl, // Added consent URL to map
      "durationMonths": durationMonths,
      "reason": reason,
      "loanableAmount": loanableAmount,
      "status": status,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}
