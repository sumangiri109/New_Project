import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/loan_model.dart';
import '../models/kyc_model.dart';

class UserDashboardServices {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // --- Get current user profile ---
  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // --- Apply for loan ---
  Future<void> applyForLoan({
    required double monthlySalary,
    required int durationMonths,
    required String reason,
    required String salaryProofUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Loanable calculation
    final eligibleAmount = monthlySalary * 0.98;
    final totalLoanAmount = eligibleAmount * durationMonths;

    final loanId = _db.collection("loans").doc().id;

    final loan = LoanModel(
      id: loanId,
      userId: user.uid,
      monthlySalary: monthlySalary,
      salaryProofUrl: salaryProofUrl,
      durationMonths: durationMonths,
      reason: reason,
      loanableAmount: totalLoanAmount,
      status: "pending",
      createdAt: DateTime.now(),
    );

    await _db.collection("loans").doc(loan.id).set(loan.toMap());
  }

  // --- Fetch current user loans ---
  Future<List<LoanModel>> getUserLoans() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final query = await _db
        .collection("loans")
        .where("userId", isEqualTo: user.uid)
        .get();
    return query.docs.map((d) => LoanModel.fromMap(d.data())).toList();
  }

  // --- Submit or update KYC ---
  Future<void> submitKYC(KYCModel kyc) async {
    await _db.collection("kyc").doc(kyc.uid).set(kyc.toMap());
  }

  // --- Fetch KYC ---
  Future<KYCModel?> getKYC() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection("kyc").doc(user.uid).get();
    if (!doc.exists) return null;
    return KYCModel.fromMap(doc.data()!);
  }
}
