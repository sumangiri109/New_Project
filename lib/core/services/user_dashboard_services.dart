import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/loan_model.dart';
import '../models/kyc_model.dart';
import '../models/notification_model.dart';

class UserDashboardServices {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Get KYC for current user
  Future<KYCModel?> getUserKYC() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection("kyc").doc(user.uid).get();
    if (!doc.exists) return null;
    return KYCModel.fromMap(doc.data()!);
  }

  // Get loans for current user
  Future<List<LoanModel>> getUserLoans() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final query = await _db
        .collection("loans")
        .where("userId", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .get();
    return query.docs.map((d) => LoanModel.fromMap(d.data())).toList();
  }

  // Listen to loans for current user
  Stream<List<LoanModel>> loanStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection("loans")
        .where("userId", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => LoanModel.fromMap(d.data())).toList(),
        );
  }

  // Listen to KYC for current user
  Stream<KYCModel?> kycStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection("kyc")
        .doc(user.uid)
        .snapshots()
        .map((snap) => snap.exists ? KYCModel.fromMap(snap.data()!) : null);
  }

  // Apply for loan
  Future<void> applyForLoan({
    required double monthlySalary,
    required int durationMonths,
    required String reason,
    required String salaryProofUrl,
    required String consentUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final loanId = _db.collection("loans").doc().id;
    final loan = LoanModel(
      id: loanId,
      userId: user.uid,
      monthlySalary: monthlySalary,
      salaryProofUrl: salaryProofUrl,
      consentUrl: consentUrl,
      durationMonths: durationMonths,
      reason: reason,
      loanableAmount: monthlySalary * 0.98,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _db.collection("loans").doc(loanId).set(loan.toMap());
  }

  // Submit KYC
  Future<void> submitKYC(KYCModel kyc) async {
    await _db.collection("kyc").doc(kyc.uid).set(kyc.toMap());
  }

  // Get notifications for current user
  Stream<List<NotificationModel>> notificationStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection("notifications")
        .where("userId", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => NotificationModel.fromMap(d.data()))
              .toList(),
        );
  }

  // Auto-complete loans that have expired
  Future<void> autoCompletExpiredLoans() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get all approved loans for current user
      final loansQuery = await _db
          .collection("loans")
          .where("userId", isEqualTo: user.uid)
          .where("status", isEqualTo: "approved")
          .get();

      final now = DateTime.now();
      final batch = _db.batch();

      for (var doc in loansQuery.docs) {
        final loan = LoanModel.fromMap(doc.data());

        // Skip if no approval date
        if (loan.approvedAt == null) continue;

        // Calculate loan end date
        final loanEndDate = loan.approvedAt!.add(
          Duration(days: loan.durationMonths * 30),
        );

        // If loan period has ended, mark as completed
        if (now.isAfter(loanEndDate)) {
          batch.update(doc.reference, {
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error auto-completing loans: $e');
    }
  }
}
