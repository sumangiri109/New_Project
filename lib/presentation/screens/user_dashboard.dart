import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/loan_model.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  Map<String, dynamic>? userData;
  List<LoanModel> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // --- Fetch user record ---
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Fallback display name
      final displayName =
          userDoc.data()?['displayName'] ??
          user.displayName ??
          user.email?.split('@').first ??
          "User";

      // --- Fetch loan history ---
      final loansSnap = await FirebaseFirestore.instance
          .collection('loans')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final loans = loansSnap.docs
          .map((d) => LoanModel.fromMap(d.data()))
          .toList();

      final latestLoan = loans.isNotEmpty ? loans.first : null;
      final activeLoan = loans.firstWhere(
        (l) => l.status == 'active',
        orElse: () =>
            latestLoan ??
            LoanModel(
              id: "none",
              userId: user.uid,
              monthlySalary: 0,
              salaryProofUrl: "",
              durationMonths: 0,
              reason: "",
              loanableAmount: 0,
              status: "none",
              createdAt: DateTime.now(),
            ),
      );

      final stats = {
        'name': displayName,
        'monthlySalary': latestLoan?.monthlySalary ?? 0.0,
        'currentLoan': activeLoan.loanableAmount,
        'loanDuration': activeLoan.durationMonths,
        'remainingMonths': (activeLoan.durationMonths > 0)
            ? activeLoan.durationMonths - 1
            : 0,
        'eligibleAmount': latestLoan?.loanableAmount ?? 0.0,
        'nextDeductionDate': activeLoan.createdAt != null
            ? activeLoan.createdAt!
                  .add(const Duration(days: 30))
                  .toString()
                  .split(" ")
                  .first
            : 'N/A',
        'loanStatus': activeLoan.status,
      };

      setState(() {
        userData = stats;
        _loans = loans;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading dashboard: $e");
      setState(() => _loading = false);
    }
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // ---------------- Sidebar ----------------
  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PayAdvance',
                  style: GoogleFonts.workSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back, ${(userData?['name'] ?? "User").split(' ')[0]}',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNavItem(0, Icons.dashboard, 'Overview'),
                  _buildNavItem(1, Icons.credit_card, 'My Loans'),
                  _buildNavItem(2, Icons.add_circle_outline, 'Apply Now'),
                  _buildNavItem(3, Icons.account_circle_outlined, 'Profile'),
                  _buildNavItem(4, Icons.help_outline, 'Help & Support'),
                  const Spacer(),
                  _buildNavItem(5, Icons.logout, 'Sign Out', isLogout: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String title, {
    bool isLogout = false,
  }) {
    final isSelected = _selectedIndex == index && !isLogout;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (isLogout) {
            FirebaseAuth.instance.signOut();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.orange.shade700
                    : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.orange.shade700
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Main ----------------
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(child: _getSelectedContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPageTitle(),
              style: GoogleFonts.workSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              _getPageSubtitle(),
              style: GoogleFonts.workSans(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.orange.shade100,
          child: Text(
            userData?['name'] != null && userData!['name'].isNotEmpty
                ? userData!['name'][0].toUpperCase()
                : "?",
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'My Loans';
      case 2:
        return 'Apply for Loan';
      case 3:
        return 'Profile Settings';
      case 4:
        return 'Help & Support';
      default:
        return 'Dashboard';
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Your financial overview at a glance';
      case 1:
        return 'Track your loan history and payments';
      case 2:
        return 'Get instant salary advance';
      case 3:
        return 'Manage your account information';
      case 4:
        return 'Get help when you need it';
      default:
        return '';
    }
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return _buildLoansContent();
      case 2:
        return _buildApplyContent();
      case 3:
        return _buildProfileContent();
      case 4:
        return _buildHelpContent();
      default:
        return _buildOverviewContent();
    }
  }

  // ---------------- Overview ----------------
  Widget _buildOverviewContent() {
    if (userData == null) return const SizedBox();
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Monthly Salary',
                  'रु ${(userData?['monthlySalary'] ?? 0).toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Available Loan',
                  'रु ${(userData?['eligibleAmount'] ?? 0).toStringAsFixed(0)}',
                  Icons.credit_card,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Loan',
                  'रु ${(userData?['currentLoan'] ?? 0).toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Remaining Months',
                  '${userData?['remainingMonths'] ?? 0}',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLoanProgressCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.workSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanProgressCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Loan Progress',
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Text('Loan Amount: रु ${userData?['currentLoan'] ?? 0}'),
          Text('Next Deduction: ${userData?['nextDeductionDate'] ?? "N/A"}'),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.5,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  // ---------------- Loans ----------------
  Widget _buildLoansContent() {
    if (_loans.isEmpty) {
      return Center(
        child: Text(
          "No loan history yet.",
          style: GoogleFonts.workSans(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: _loans.length,
      itemBuilder: (context, i) {
        final loan = _loans[i];
        return ListTile(
          title: Text("रु ${loan.loanableAmount.toStringAsFixed(0)}"),
          subtitle: Text(
            "${loan.durationMonths} months • ${loan.createdAt?.toString().split(' ').first ?? ''}",
          ),
          trailing: Chip(label: Text(loan.status)),
        );
      },
    );
  }

  // ---------------- Apply + Profile + Help ----------------
  Widget _buildApplyContent() =>
      const Center(child: Text("Loan Application Form here"));

  Widget _buildProfileContent() =>
      Center(child: Text("Settings for ${userData?['name'] ?? "User"}"));

  Widget _buildHelpContent() =>
      const Center(child: Text("Help & Support here"));
}
