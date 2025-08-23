// lib/core/services/admin_dashboard_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/loan_model.dart';
import '../models/kyc_model.dart';

class AdminDashboardServices {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) return false;
    
    final userData = UserModel.fromMap(doc.data()!);
    return userData.role.toLowerCase() == 'admin';
  }

  // --- LOAN MANAGEMENT ---
  
  // Get all loan applications with pagination
  Stream<QuerySnapshot> getLoanApplicationsStream({
    String? status,
    int limit = 50,
  }) {
    Query query = _db.collection("loans").orderBy("createdAt", descending: true);
    
    if (status != null && status.isNotEmpty) {
      query = query.where("status", isEqualTo: status);
    }
    
    return query.limit(limit).snapshots();
  }

  // Get loan details with user info
  Future<Map<String, dynamic>?> getLoanDetailsWithUser(String loanId) async {
    try {
      final loanDoc = await _db.collection("loans").doc(loanId).get();
      if (!loanDoc.exists) return null;
      
      final loan = LoanModel.fromMap(loanDoc.data()!);
      
      // Get user details
      final userDoc = await _db.collection("users").doc(loan.userId).get();
      UserModel? user;
      if (userDoc.exists) {
        user = UserModel.fromMap(userDoc.data()!);
      }
      
      // Get KYC details
      final kycDoc = await _db.collection("kyc").doc(loan.userId).get();
      KYCModel? kyc;
      if (kycDoc.exists) {
        kyc = KYCModel.fromMap(kycDoc.data()!);
      }
      
      return {
        'loan': loan,
        'user': user,
        'kyc': kyc,
      };
    } catch (e) {
      print('Error getting loan details: $e');
      return null;
    }
  }

  // Approve loan application
  Future<void> approveLoan(String loanId, String comment) async {
    final batch = _db.batch();
    
    final loanRef = _db.collection("loans").doc(loanId);
    batch.update(loanRef, {
      'status': 'approved',
      'adminComment': comment,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });
    
    // Create notification for user
    final loanDoc = await loanRef.get();
    if (loanDoc.exists) {
      final loan = LoanModel.fromMap(loanDoc.data()!);
      final notificationRef = _db.collection("notifications").doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': loan.userId,
        'title': 'Loan Approved',
        'message': 'Your loan application has been approved. $comment',
        'type': 'loan_approved',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  // Decline loan application
  Future<void> declineLoan(String loanId, String comment) async {
    final batch = _db.batch();
    
    final loanRef = _db.collection("loans").doc(loanId);
    batch.update(loanRef, {
      'status': 'declined',
      'adminComment': comment,
      'declinedAt': FieldValue.serverTimestamp(),
      'declinedBy': _auth.currentUser?.uid,
    });
    
    // Create notification for user
    final loanDoc = await loanRef.get();
    if (loanDoc.exists) {
      final loan = LoanModel.fromMap(loanDoc.data()!);
      final notificationRef = _db.collection("notifications").doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': loan.userId,
        'title': 'Loan Declined',
        'message': 'Your loan application has been declined. Reason: $comment',
        'type': 'loan_declined',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  // --- KYC MANAGEMENT ---
  
  // Get all KYC applications
  Stream<QuerySnapshot> getKYCApplicationsStream({
    bool? verified,
    int limit = 50,
  }) {
    Query query = _db.collection("kyc").orderBy("submittedAt", descending: true);
    
    if (verified != null) {
      query = query.where("verified", isEqualTo: verified);
    }
    
    return query.limit(limit).snapshots();
  }

  // Get KYC details with user info
  Future<Map<String, dynamic>?> getKYCDetailsWithUser(String userId) async {
    try {
      final kycDoc = await _db.collection("kyc").doc(userId).get();
      if (!kycDoc.exists) return null;
      
      final kyc = KYCModel.fromMap(kycDoc.data()!);
      
      // Get user details
      final userDoc = await _db.collection("users").doc(userId).get();
      UserModel? user;
      if (userDoc.exists) {
        user = UserModel.fromMap(userDoc.data()!);
      }
      
      return {
        'kyc': kyc,
        'user': user,
      };
    } catch (e) {
      print('Error getting KYC details: $e');
      return null;
    }
  }

  // Approve KYC
  Future<void> approveKYC(String userId, String comment) async {
    final batch = _db.batch();
    
    final kycRef = _db.collection("kyc").doc(userId);
    batch.update(kycRef, {
      'verified': true,
      'adminComment': comment,
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': _auth.currentUser?.uid,
    });
    
    // Create notification for user
    final notificationRef = _db.collection("notifications").doc();
    batch.set(notificationRef, {
      'id': notificationRef.id,
      'userId': userId,
      'title': 'KYC Verified',
      'message': 'Your KYC has been verified successfully. $comment',
      'type': 'kyc_verified',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  // Decline KYC
  Future<void> declineKYC(String userId, String comment) async {
    final batch = _db.batch();
    
    final kycRef = _db.collection("kyc").doc(userId);
    batch.update(kycRef, {
      'verified': false,
      'adminComment': comment,
      'declinedAt': FieldValue.serverTimestamp(),
      'declinedBy': _auth.currentUser?.uid,
    });
    
    // Create notification for user
    final notificationRef = _db.collection("notifications").doc();
    batch.set(notificationRef, {
      'id': notificationRef.id,
      'userId': userId,
      'title': 'KYC Declined',
      'message': 'Your KYC has been declined. Reason: $comment',
      'type': 'kyc_declined',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  // --- USER MANAGEMENT ---
  
  // Get all users with pagination
  Stream<QuerySnapshot> getUsersStream({int limit = 50}) {
    return _db.collection("users")
        .orderBy("createdAt", descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get user details with KYC and loans
  Future<Map<String, dynamic>?> getUserDetailsComplete(String userId) async {
    try {
      // Get user
      final userDoc = await _db.collection("users").doc(userId).get();
      if (!userDoc.exists) return null;
      final user = UserModel.fromMap(userDoc.data()!);
      
      // Get KYC
      final kycDoc = await _db.collection("kyc").doc(userId).get();
      KYCModel? kyc;
      if (kycDoc.exists) {
        kyc = KYCModel.fromMap(kycDoc.data()!);
      }
      
      // Get loans
      final loansQuery = await _db.collection("loans")
          .where("userId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .get();
      final loans = loansQuery.docs
          .map((d) => LoanModel.fromMap(d.data()))
          .toList();
      
      return {
        'user': user,
        'kyc': kyc,
        'loans': loans,
      };
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, String role) async {
    await _db.collection("users").doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });
  }

  // --- DASHBOARD ANALYTICS ---
  
  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      // Total users
      final usersSnapshot = await _db.collection("users").get();
      final totalUsers = usersSnapshot.docs.length;
      
      // Total loans
      final loansSnapshot = await _db.collection("loans").get();
      final totalLoans = loansSnapshot.docs.length;
      
      // Active loans
      final activeLoansSnapshot = await _db.collection("loans")
          .where("status", isEqualTo: "approved")
          .get();
      final activeLoans = activeLoansSnapshot.docs.length;
      
      // Pending loans
      final pendingLoansSnapshot = await _db.collection("loans")
          .where("status", isEqualTo: "pending")
          .get();
      final pendingLoans = pendingLoansSnapshot.docs.length;
      
      // Total loan amount
      double totalLoanAmount = 0;
      for (var doc in activeLoansSnapshot.docs) {
        final loan = LoanModel.fromMap(doc.data());
        totalLoanAmount += loan.loanableAmount;
      }
      
      // KYC stats
      final kycSnapshot = await _db.collection("kyc").get();
      final totalKYC = kycSnapshot.docs.length;
      
      final verifiedKYCSnapshot = await _db.collection("kyc")
          .where("verified", isEqualTo: true)
          .get();
      final verifiedKYC = verifiedKYCSnapshot.docs.length;
      
      final pendingKYCSnapshot = await _db.collection("kyc")
          .where("verified", isEqualTo: false)
          .get();
      final pendingKYC = pendingKYCSnapshot.docs.length;
      
      // New users this month
      final newUsersThisMonth = await _db.collection("users")
          .where("createdAt", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();
      
      // New loans this week
      final newLoansThisWeek = await _db.collection("loans")
          .where("createdAt", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();
      
      return {
        'totalUsers': totalUsers,
        'totalLoans': totalLoans,
        'activeLoans': activeLoans,
        'pendingLoans': pendingLoans,
        'totalLoanAmount': totalLoanAmount,
        'totalKYC': totalKYC,
        'verifiedKYC': verifiedKYC,
        'pendingKYC': pendingKYC,
        'newUsersThisMonth': newUsersThisMonth.docs.length,
        'newLoansThisWeek': newLoansThisWeek.docs.length,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalLoans': 0,
        'activeLoans': 0,
        'pendingLoans': 0,
        'totalLoanAmount': 0.0,
        'totalKYC': 0,
        'verifiedKYC': 0,
        'pendingKYC': 0,
        'newUsersThisMonth': 0,
        'newLoansThisWeek': 0,
      };
    }
  }

  // Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 20}) async {
    List<Map<String, dynamic>> activities = [];
    
    try {
      // Recent loan applications
      final recentLoans = await _db.collection("loans")
          .orderBy("createdAt", descending: true)
          .limit(limit ~/ 2)
          .get();
      
      for (var doc in recentLoans.docs) {
        final loan = LoanModel.fromMap(doc.data());
        final userDoc = await _db.collection("users").doc(loan.userId).get();
        final userName = userDoc.exists 
            ? UserModel.fromMap(userDoc.data()!).displayName 
            : 'Unknown User';
        
        activities.add({
          'id': loan.id,
          'type': 'loan',
          'title': 'New Loan Application',
          'description': '$userName applied for रु${loan.loanableAmount.toStringAsFixed(0)}',
          'status': loan.status,
          'createdAt': loan.createdAt,
          'userId': loan.userId,
        });
      }
      
      // Recent KYC submissions
      final recentKYC = await _db.collection("kyc")
          .orderBy("submittedAt", descending: true)
          .limit(limit ~/ 2)
          .get();
      
      for (var doc in recentKYC.docs) {
        final kyc = KYCModel.fromMap(doc.data());
        activities.add({
          'id': kyc.uid,
          'type': 'kyc',
          'title': 'KYC Submission',
          'description': '${kyc.fullName} submitted KYC documents',
          'status': kyc.verified ? 'verified' : 'pending',
          'createdAt': kyc.submittedAt,
          'userId': kyc.uid,
        });
      }
      
      // Sort by date
      activities.sort((a, b) {
        final aDate = a['createdAt'] as DateTime?;
        final bDate = b['createdAt'] as DateTime?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
      
      return activities.take(limit).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  // --- NOTIFICATIONS ---
  
  // Send notification to user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    final notificationRef = _db.collection("notifications").doc();
    await notificationRef.set({
      'id': notificationRef.id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'read': false,
      'sentBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Send broadcast notification
  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final usersSnapshot = await _db.collection("users").get();
    final batch = _db.batch();
    
    for (var userDoc in usersSnapshot.docs) {
      final notificationRef = _db.collection("notifications").doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userDoc.id,
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'sentBy': _auth.currentUser?.uid,
        'broadcast': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }
}