// lib/presentation/screens/user_dashboard_page.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:loan_project/core/models/kyc_model.dart';
import 'package:loan_project/core/models/loan_model.dart';
import 'package:loan_project/core/models/user_model.dart';
import 'package:loan_project/core/services/auth_page_services.dart';
import 'package:loan_project/core/services/user_dashboard_services.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final AuthPageServices _authService = AuthPageServices();
  final UserDashboardServices _dashboardService = UserDashboardServices();

  UserModel? _profile;
  KYCModel? _kyc;
  List<LoanModel> _loans = [];
  bool _loading = true;
  int _selectedIndex = 0;

  // Form controllers
  final _monthlySalaryController = TextEditingController();
  final _loanPurposeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();

  // Duration selection
  int _selectedDurationMonths = 1;

  // Realtime listeners
  StreamSubscription<DocumentSnapshot<Object?>>? _kycSub;
  StreamSubscription<QuerySnapshot<Object?>>? _loansSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _kycSub?.cancel();
    _loansSub?.cancel();
    _monthlySalaryController.dispose();
    _loanPurposeController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);

    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final profile = await _dashboardService.getUserProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      // ignore
    }

    final uid = user.uid;
    _kycSub = FirebaseFirestore.instance
        .collection('kyc')
        .doc(uid)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          if (snap.exists && snap.data() != null) {
            try {
              setState(
                () => _kyc = KYCModel.fromMap(
                  snap.data() as Map<String, dynamic>,
                ),
              );
            } catch (_) {}
          } else {
            setState(() => _kyc = null);
          }
        });

    _loansSub = FirebaseFirestore.instance
        .collection('loans')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((qSnap) {
          if (!mounted) return;
          final loansList = qSnap.docs.map((d) {
            final map = d.data() as Map<String, dynamic>;
            return LoanModel.fromMap(map);
          }).toList();
          setState(() => _loans = loansList);
        });

    if (mounted) setState(() => _loading = false);
  }

  // UI helpers
  String _displayName() => _profile?.displayName.isNotEmpty == true
      ? _profile!.displayName
      : 'No Name';
  String _email() => _profile?.email ?? 'No Email';
  String _avatarLetter() => (_profile?.displayName.isNotEmpty == true)
      ? _profile!.displayName[0]
      : (_profile?.email.isNotEmpty == true ? _profile!.email[0] : 'U');

  double? get _monthlySalaryFromLoans =>
      _loans.isNotEmpty ? _loans.first.monthlySalary : null;
  double get _eligibleAmount => (_monthlySalaryFromLoans != null)
      ? (_monthlySalaryFromLoans! * 0.98)
      : 0.0;
  LoanModel? get _activeLoan {
    for (final l in _loans) {
      final s = l.status.toLowerCase();
      if (s == 'active' ||
          s == 'pending' ||
          s == 'ongoing' ||
          s == 'in-progress')
        return l;
    }
    return null;
  }

  // Image picker
  Future<File?> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x == null) return null;
    return File(x.path);
  }

  // Submit KYC
  Future<void> _submitKYCToService({
    required String fullName,
    required String phone,
    required String dateOfBirth,
    required String citizenshipNumber,
    File? citizenshipFile,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      String photoUrl = _kyc?.citizenshipPhotoUrl ?? '';

      if (citizenshipFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'kyc/${user.uid}/citizenship_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(citizenshipFile);
        photoUrl = await ref.getDownloadURL();
      }

      final kyc = KYCModel(
        uid: user.uid,
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        citizenshipNumber: citizenshipNumber,
        citizenshipPhotoUrl: photoUrl,
        verified: false,
        submittedAt: DateTime.now(),
      );

      await _dashboardService.submitKYC(kyc);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KYC submitted successfully. Pending verification.'),
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('KYC submission failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Apply for loan: now uploads salary proof and consent file (if any)
  Future<void> _applyForLoanToService({
    required double monthlySalary,
    required int durationMonths,
    required String reason,
    File? salaryProof,
    File? consentFile,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (_kyc == null || _kyc?.verified != true) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete KYC and wait for verification before applying.',
            ),
          ),
        );
      return;
    }

    setState(() => _loading = true);
    try {
      String proofUrl = '';
      String consentUrl = '';

      if (salaryProof != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'loans/${user.uid}/salary_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(salaryProof);
        proofUrl = await ref.getDownloadURL();
      }

      if (consentFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'loans/${user.uid}/consent_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(consentFile);
        consentUrl = await ref.getDownloadURL();
      }

      // Note: your existing service applyForLoan expects salaryProofUrl; we'll store consentUrl in reason appended
      // but ideally extend service to accept consentUrl. For now, append consent URL to reason as structured info.
      final fullReason =
          reason + (consentUrl.isNotEmpty ? '\nCONSENT_URL:$consentUrl' : '');

      await _dashboardService.applyForLoan(
        monthlySalary: monthlySalary,
        durationMonths: durationMonths,
        reason: fullReason,
        salaryProofUrl: proofUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan application submitted successfully'),
        ),
      );

      _monthlySalaryController.clear();
      _loanPurposeController.clear();
      _selectedDurationMonths = 1;
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Loan application failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Dev helper
  Future<void> _devFlagKycVerified() async {
    if (!kDebugMode) return;
    final user = _authService.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('kyc').doc(user.uid).set({
      'verified': true,
    }, SetOptions(merge: true));
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC set to VERIFIED (dev)')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
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
                  'Welcome back, ${_displayName().split(' ').first}',
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
                  _buildNavItem(2, Icons.add_circle_outline, 'Apply Loan'),
                  _buildNavItem(3, Icons.verified_user, 'KYC Verification'),
                  _buildNavItem(4, Icons.account_circle_outlined, 'Profile'),
                  _buildNavItem(5, Icons.settings, 'Settings'),
                  _buildNavItem(6, Icons.help_outline, 'Help & Support'),
                  const Spacer(),
                  if (kDebugMode)
                    TextButton(
                      onPressed: _devFlagKycVerified,
                      child: Text(
                        'DEV: verify KYC',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade600,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 20),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
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
      ),
    );
  }

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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey.shade600,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orange.shade100,
              child: Text(
                _avatarLetter(),
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
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
        return 'KYC Verification';
      case 4:
        return 'Profile Settings';
      case 5:
        return 'Settings';
      case 6:
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
        return 'Complete your identity verification';
      case 4:
        return 'Manage your account information';
      case 5:
        return 'Customize your preferences';
      case 6:
        return 'Get help when you need it';
      default:
        return '';
    }
  }

  Widget _getSelectedContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return _buildLoansContent();
      case 2:
        return _buildApplyContent();
      case 3:
        return _buildKYCContent();
      case 4:
        return _buildProfileContent();
      case 5:
        return _buildSettingsContent();
      case 6:
        return _buildHelpContent();
      default:
        return _buildOverviewContent();
    }
  }

  // ---------- Overview UI (unchanged design) ----------
  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Monthly Salary',
                  _monthlySalaryFromLoans != null
                      ? 'रु ${_monthlySalaryFromLoans!.toStringAsFixed(0)}'
                      : 'N/A',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Available Loan',
                  'रु ${_eligibleAmount.toStringAsFixed(0)}',
                  Icons.credit_card,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Loan',
                  _activeLoan != null
                      ? 'रु ${_activeLoan!.loanableAmount.toStringAsFixed(0)}'
                      : 'N/A',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Remaining Months',
                  _activeLoan != null
                      ? '${_activeLoan!.durationMonths}'
                      : 'N/A',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildLoanProgressCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickActionsCard()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNotificationsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFinancialHealthCard()),
            ],
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
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
    final active = _activeLoan;
    final loanAmountStr = active != null
        ? 'रु ${active.loanableAmount.toStringAsFixed(0)}'
        : 'N/A';
    final nextDeduction = active != null
        ? (active.createdAt != null ? _formatDate(active.createdAt!) : 'N/A')
        : 'N/A';

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loan Amount: $loanAmountStr',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Next Deduction: $nextDeduction',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 month completed',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                '1 month remaining',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildQuickActionsCard() {
    return Container(
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
            'Quick Actions',
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            'Apply for New Loan',
            Icons.add_circle_outline,
            Colors.orange,
            () {
              if (_kyc?.verified == true)
                setState(() => _selectedIndex = 2);
              else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please complete KYC before applying for a loan.',
                    ),
                  ),
                );
                setState(() => _selectedIndex = 3);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Complete KYC',
            Icons.verified_user,
            Colors.blue,
            () => setState(() => _selectedIndex = 3),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Update Profile',
            Icons.edit_outlined,
            Colors.green,
            () => setState(() => _selectedIndex = 4),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Contact Support',
            Icons.support_agent,
            Colors.purple,
            () => setState(() => _selectedIndex = 6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final notifications = [
      {
        'type': 'reminder',
        'title': 'Salary Deduction Scheduled',
        'message': 'Your salary deduction is scheduled for Sep 1, 2025',
        'time': '2 hours ago',
        'icon': Icons.schedule,
        'color': Colors.orange,
      },
      {
        'type': 'tip',
        'title': 'Financial Tip',
        'message': 'Track your expenses to improve financial health',
        'time': '1 day ago',
        'icon': Icons.lightbulb_outline,
        'color': Colors.blue,
      },
      {
        'type': 'success',
        'title': 'Loan Approved',
        'message': 'Your loan has been approved successfully',
        'time': '3 days ago',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      },
    ];

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: GoogleFonts.workSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...notifications
              .take(3)
              .map((n) => _buildNotificationItem(n))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final Color color = notification['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              notification['icon'] as IconData,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  notification['message'] as String,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  notification['time'] as String,
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard() {
    return Container(
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
            'Financial Health',
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade500,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '75',
                      style: GoogleFonts.workSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                    Text(
                      'Good',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your financial health is good! Keep tracking your expenses and maintain regular payments.',
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------- Loans UI ----------
  Widget _buildLoansContent() {
    return Container(
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
            'Loan History',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loans.isEmpty
                ? Center(
                    child: Text(
                      'You have no loans yet.',
                      style: GoogleFonts.workSans(),
                    ),
                  )
                : ListView.builder(
                    itemCount: _loans.length,
                    itemBuilder: (context, index) {
                      final loan = _loans[index];
                      final statusColor =
                          loan.status.toLowerCase() == 'completed'
                          ? Colors.green
                          : Colors.orange;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                loan.status.toLowerCase() == 'active'
                                    ? Icons.schedule
                                    : Icons.check_circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'रु ${loan.loanableAmount.toStringAsFixed(0)}',
                                    style: GoogleFonts.workSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    'Duration: ${loan.durationMonths} months',
                                    style: GoogleFonts.workSans(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Applied: ${loan.createdAt != null ? _formatDate(loan.createdAt!) : 'N/A'}',
                                    style: GoogleFonts.workSans(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                loan.status,
                                style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- Apply UI (CHANGED) ----------
  Widget _buildApplyContent() {
    if (_kyc == null || _kyc?.verified != true) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 48, color: Colors.orange.shade600),
              const SizedBox(height: 12),
              Text(
                _kyc == null ? 'KYC Required' : 'KYC Pending Verification',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _kyc == null
                    ? 'Please complete your KYC before applying for a loan.'
                    : 'Your KYC is submitted and waiting for admin verification. You will be able to apply when it is verified.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _selectedIndex = 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
                child: Text('Complete KYC', style: GoogleFonts.workSans()),
              ),
            ],
          ),
        ),
      );
    }

    File? salaryFile;
    File? consentFile;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: Colors.orange.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salary Advance Application',
                      style: GoogleFonts.workSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Get up to 98% of your monthly salary instantly',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are eligible for',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'रु ${_eligibleAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.workSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Application Details',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // Monthly Salary (user provides)
            _buildFormField(
              label: 'Monthly Salary (रु)',
              controller: _monthlySalaryController,
              hint: 'Enter your monthly salary',
              icon: Icons.account_balance_wallet,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Purpose
            _buildFormField(
              label: 'Purpose of Loan',
              controller: _loanPurposeController,
              hint: 'e.g., Medical emergency, Education, etc.',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Duration
            Text(
              'Repayment Duration',
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDurationCard('1 Month', 1, _selectedDurationMonths == 1),
                const SizedBox(width: 12),
                _buildDurationCard('2 Months', 2, _selectedDurationMonths == 2),
                const SizedBox(width: 12),
                _buildDurationCard('3 Months', 3, _selectedDurationMonths == 3),
              ],
            ),
            const SizedBox(height: 20),

            // Salary proof + consent uploads
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final f = await _pickImageFromGallery();
                    if (f != null) {
                      salaryFile = f;
                      if (mounted) setState(() {});
                    }
                  },
                  child: const Text('Upload Salary Proof'),
                ),
                const SizedBox(width: 12),
                salaryFile != null
                    ? const Icon(Icons.check, color: Colors.green)
                    : const SizedBox(),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () async {
                    final f = await _pickImageFromGallery();
                    if (f != null) {
                      consentFile = f;
                      if (mounted) setState(() {});
                    }
                  },
                  child: const Text('Upload Consent Form'),
                ),
                const SizedBox(width: 12),
                consentFile != null
                    ? const Icon(Icons.check, color: Colors.green)
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final salary =
                      double.tryParse(_monthlySalaryController.text) ?? 0;
                  final duration = _selectedDurationMonths;
                  final reason = _loanPurposeController.text.trim();
                  if (salary <= 0 || duration <= 0 || reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all application fields'),
                      ),
                    );
                    return;
                  }
                  _applyForLoanToService(
                    monthlySalary: salary,
                    durationMonths: duration,
                    reason: reason,
                    salaryProof: salaryFile,
                    consentFile: consentFile,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit Application',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard(String title, int months, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDurationMonths = months),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$months',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.orange.shade600
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- KYC, Profile, Settings, Help (kept same) ----------
  Widget _buildKYCContent() {
    _fullNameController.text = _kyc?.fullName ?? _fullNameController.text;
    _phoneController.text = _kyc?.phone ?? _phoneController.text;
    _panController.text = _kyc?.citizenshipNumber ?? _panController.text;

    File? citizenshipFile;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: Colors.blue.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Verification',
                      style: GoogleFonts.workSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Complete your identity verification',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _kyc?.verified == true
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.orange.shade50, Colors.orange.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kyc?.verified == true
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _kyc?.verified == true ? Icons.check_circle : Icons.pending,
                    color: _kyc?.verified == true
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _kyc?.verified == true ? 'KYC Verified' : 'KYC Pending',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kyc?.verified == true
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    _kyc?.verified == true
                        ? 'Your identity has been successfully verified'
                        : 'Please complete the verification process',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: _kyc?.verified == true
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_kyc?.verified != true) ...[
              Text(
                'Personal Information',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              _buildFormField(
                label: 'Full Name',
                controller: _fullNameController,
                hint: 'Enter your full name as per ID',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                label: 'Phone Number',
                controller: _phoneController,
                hint: 'Enter your phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                label: 'Date of Birth',
                controller: TextEditingController(
                  text: _kyc?.dateOfBirth ?? '',
                ),
                hint: 'YYYY-MM-DD',
                icon: Icons.cake,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                label: 'Citizenship Number',
                controller: _panController,
                hint: 'Enter your citizenship number',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 32),
              Text(
                'Document Upload',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              _buildDocumentUpload(
                'Citizenship/Passport',
                Icons.credit_card,
                onUpload: () async {
                  final f = await _pickImageFromGallery();
                  if (f != null) {
                    citizenshipFile = f;
                    if (mounted) setState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildDocumentUpload(
                'Photo',
                Icons.camera_alt,
                onUpload: () async {
                  final f = await _pickImageFromGallery();
                  if (f != null) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Photo picked (not uploaded separately)',
                          ),
                        ),
                      );
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final fullName = _fullNameController.text.trim();
                    final phone = _phoneController.text.trim();
                    final dob = ''; // optional
                    final citizenshipNumber = _panController.text.trim();
                    if (fullName.isEmpty ||
                        phone.isEmpty ||
                        citizenshipNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill required KYC fields'),
                        ),
                      );
                      return;
                    }
                    _submitKYCToService(
                      fullName: fullName,
                      phone: phone,
                      dateOfBirth: dob,
                      citizenshipNumber: citizenshipNumber,
                      citizenshipFile: citizenshipFile,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Submit KYC',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(
    String title,
    IconData icon, {
    required Future<void> Function() onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.workSans(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              elevation: 0,
            ),
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final monthlySalaryStr = _monthlySalaryFromLoans != null
        ? 'रु ${_monthlySalaryFromLoans!.toStringAsFixed(0)}'
        : 'रु 0';
    final eligibleStr = 'रु ${_eligibleAmount.toStringAsFixed(0)}';
    final currentLoanStr = _activeLoan != null
        ? 'रु ${_activeLoan!.loanableAmount.toStringAsFixed(0)}'
        : 'रु 0';
    final kycStatus = _kyc?.verified == true ? 'verified' : 'pending';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    _avatarLetter(),
                    style: GoogleFonts.workSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(),
                        style: GoogleFonts.workSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        _email(),
                        style: GoogleFonts.workSans(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Account',
                            style: GoogleFonts.workSans(
                              fontSize: 14,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange.shade700,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildProfileSection('Personal Information', [
              _buildProfileItem('Full Name', _displayName(), Icons.person),
              _buildProfileItem('Email', _email(), Icons.email),
              _buildProfileItem('Phone', _kyc?.phone ?? '-', Icons.phone),
              _buildProfileItem(
                'Address',
                _kyc?.citizenshipNumber ?? '-',
                Icons.location_on,
              ),
            ]),
            const SizedBox(height: 24),
            _buildProfileSection('Employment Information', [
              _buildProfileItem(
                'Monthly Salary',
                monthlySalaryStr,
                Icons.account_balance_wallet,
              ),
              _buildProfileItem(
                'Join Date',
                _profile?.createdAt != null
                    ? _formatDate(_profile!.createdAt!)
                    : '-',
                Icons.calendar_today,
              ),
              _buildProfileItem(
                'KYC Status',
                kycStatus.toUpperCase(),
                Icons.verified_user,
              ),
            ]),
            const SizedBox(height: 24),
            _buildProfileSection('Loan Information', [
              _buildProfileItem(
                'Eligible Amount',
                eligibleStr,
                Icons.credit_card,
              ),
              _buildProfileItem(
                'Current Loan',
                currentLoanStr,
                Icons.trending_up,
              ),
              _buildProfileItem(
                'Loan Status',
                _activeLoan?.status.toUpperCase() ?? 'N/A',
                Icons.info,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.workSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Container(
      padding: const EdgeInsets.all(32),
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
            'Settings',
            style: GoogleFonts.workSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingItem(
            'Notifications',
            'Manage notification preferences',
            Icons.notifications,
            true,
          ),
          _buildSettingItem(
            'Email Alerts',
            'Get updates via email',
            Icons.email,
            true,
          ),
          _buildSettingItem(
            'SMS Alerts',
            'Get updates via SMS',
            Icons.sms,
            false,
          ),
          _buildSettingItem(
            'Dark Mode',
            'Switch to dark theme',
            Icons.dark_mode,
            false,
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 24),
          _buildSettingButton(
            'Change Password',
            'Update your account password',
            Icons.lock,
            Colors.blue,
          ),
          _buildSettingButton(
            'Two-Factor Authentication',
            'Add extra security to your account',
            Icons.security,
            Colors.green,
          ),
          _buildSettingButton(
            'Delete Account',
            'Permanently delete your account',
            Icons.delete,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpContent() {
    return Container(
      padding: const EdgeInsets.all(32),
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
            'Help & Support',
            style: GoogleFonts.workSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 32),
          _buildHelpCard(
            'Frequently Asked Questions',
            'Find answers to common questions',
            Icons.help_outline,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildHelpCard(
            'Contact Support',
            'Get in touch with our support team',
            Icons.support_agent,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildHelpCard(
            'Live Chat',
            'Chat with us in real-time',
            Icons.chat,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildHelpCard(
            'Report an Issue',
            'Report bugs or technical issues',
            Icons.bug_report,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {},
            activeColor: Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade500),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.workSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.workSans(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                if (mounted)
                  Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Sign Out', style: GoogleFonts.workSans()),
            ),
          ],
        );
      },
    );
  }
}
