// lib/presentation/screens/user_dashboard.dart
// Replace your existing file with this web-compatible version

import 'dart:async';

import 'dart:typed_data'; //  Add this for Uint8List
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
  final _dobController = TextEditingController();

  // Duration selection
  int _selectedDurationMonths = 1;

  // ✅ CHANGE: Use XFile instead of File for web compatibility
  XFile? _salaryProofFile;
  XFile? _consentFile;
  XFile? _citizenshipFile;

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
    _dobController.dispose();
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

  // ✅ FIXED: Web-compatible image picker using XFile
  Future<XFile?> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        // Validate file size
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          throw Exception('File size must be less than 5MB');
        }

        if (kDebugMode) {
          print('✅ File selected: ${pickedFile.name}');
          print('✅ File size: ${bytes.length} bytes');
        }
      }

      return pickedFile;
    } catch (e) {
      if (kDebugMode) print('❌ Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
      return null;
    }
  }

  // ✅ FIXED: Web-compatible file upload using putData instead of putFile
  Future<String> _uploadFileToFirebaseStorage(XFile file, String path) async {
    try {
      if (kDebugMode) print('📤 Starting upload to: $path');

      // Read file as bytes - works on all platforms
      final Uint8List bytes = await file.readAsBytes();
      if (kDebugMode) print('📋 File loaded: ${bytes.length} bytes');

      // Get Firebase Storage reference
      final Reference ref = FirebaseStorage.instance.ref().child(path);

      // Create metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(file.name),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': file.name,
          'fileSize': bytes.length.toString(),
        },
      );

      // ✅ Use putData() for web - NOT putFile()
      final UploadTask uploadTask = ref.putData(bytes, metadata);

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final String downloadURL = await ref.getDownloadURL();
        if (kDebugMode) print('✅ Upload successful: $downloadURL');
        return downloadURL;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) print('❌ Firebase error: ${e.code} - ${e.message}');
      throw Exception('Firebase upload error: ${e.message ?? e.code}');
    } catch (e) {
      if (kDebugMode) print('❌ Upload error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // Helper method to get content type
  String _getContentType(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  // ✅ FIXED: KYC submission with proper web upload
  Future<void> _submitKYCToService({
    required String fullName,
    required String phone,
    required String dateOfBirth,
    required String citizenshipNumber,
    XFile? citizenshipFile,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      _showErrorMessage('Please log in again');
      return;
    }

    // Basic validation
    if (fullName.trim().isEmpty ||
        phone.trim().isEmpty ||
        dateOfBirth.trim().isEmpty ||
        citizenshipNumber.trim().isEmpty) {
      _showErrorMessage('Please fill all required fields');
      return;
    }

    if (citizenshipFile == null &&
        (_kyc?.citizenshipPhotoUrl?.isEmpty ?? true)) {
      _showErrorMessage('Please upload citizenship photo');
      return;
    }

    setState(() => _loading = true);

    try {
      String photoUrl = _kyc?.citizenshipPhotoUrl ?? '';

      if (citizenshipFile != null) {
        if (kDebugMode) print('📤 Uploading citizenship file...');
        final fileName =
            'citizenship_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${citizenshipFile.name.split('.').last}';
        final path = 'kyc/${user.uid}/$fileName';
        photoUrl = await _uploadFileToFirebaseStorage(citizenshipFile, path);
      }

      final kyc = KYCModel(
        uid: user.uid,
        fullName: fullName.trim(),
        phone: phone.trim(),
        dateOfBirth: dateOfBirth.trim(),
        citizenshipNumber: citizenshipNumber.trim(),
        citizenshipPhotoUrl: photoUrl,
        verified: false,
        submittedAt: DateTime.now(),
      );

      await _dashboardService.submitKYC(kyc);

      if (mounted) {
        _showSuccessMessage(
          'KYC submitted successfully! Waiting for verification.',
        );
        setState(() => _citizenshipFile = null);
      }
    } catch (e) {
      if (kDebugMode) print('❌ KYC submission error: $e');
      if (mounted) {
        _showErrorMessage(
          'KYC submission failed: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ FIXED: Loan application with proper web upload
  Future<void> _applyForLoanToService({
    required double monthlySalary,
    required int durationMonths,
    required String reason,
    XFile? salaryProof,
    XFile? consentFile,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      _showErrorMessage('Please log in again');
      return;
    }

    if (_kyc == null || _kyc?.verified != true) {
      _showErrorMessage('Complete KYC verification before applying');
      return;
    }

    // Validation
    if (monthlySalary < 10000) {
      _showErrorMessage('Minimum salary requirement is रु 10,000');
      return;
    }

    if (reason.trim().length < 10) {
      _showErrorMessage(
        'Please provide detailed reason (minimum 10 characters)',
      );
      return;
    }

    if (salaryProof == null) {
      _showErrorMessage('Salary proof document is required');
      return;
    }

    setState(() => _loading = true);

    try {
      String proofUrl = '';
      String consentUrl = '';

      // Upload salary proof (required)
      if (kDebugMode) print('📤 Uploading salary proof...');
      final proofFileName =
          'salary_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${salaryProof.name.split('.').last}';
      final proofPath = 'loans/${user.uid}/$proofFileName';
      proofUrl = await _uploadFileToFirebaseStorage(salaryProof, proofPath);

      // Upload consent file (optional)
      if (consentFile != null) {
        if (kDebugMode) print('📤 Uploading consent file...');
        final consentFileName =
            'consent_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${consentFile.name.split('.').last}';
        final consentPath = 'loans/${user.uid}/$consentFileName';
        consentUrl = await _uploadFileToFirebaseStorage(
          consentFile,
          consentPath,
        );
      }

      // Submit loan application
      await _dashboardService.applyForLoan(
        monthlySalary: monthlySalary,
        durationMonths: durationMonths,
        reason: reason.trim(),
        salaryProofUrl: proofUrl,
        consentUrl: consentUrl,
      );

      if (mounted) {
        _showSuccessMessage('Loan application submitted successfully!');
        // Clear form
        _monthlySalaryController.clear();
        _loanPurposeController.clear();
        _selectedDurationMonths = 1;
        setState(() {
          _salaryProofFile = null;
          _consentFile = null;
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Loan application error: $e');
      if (mounted) {
        _showErrorMessage(
          'Loan application failed: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Helper methods for showing messages
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  // ---------- Overview UI ----------
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No loans yet',
                          style: GoogleFonts.workSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'Apply for your first loan to get started',
                          style: GoogleFonts.workSans(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedIndex = 2),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Apply for Loan',
                            style: GoogleFonts.workSans(),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _loans.length,
                    itemBuilder: (context, index) {
                      final loan = _loans[index];
                      final statusColor = _getStatusColor(loan.status);
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
                                _getStatusIcon(loan.status),
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
                                  if (loan.reason.isNotEmpty)
                                    Text(
                                      'Purpose: ${loan.reason}',
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
                                loan.status.toUpperCase(),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'denied':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
      case 'denied':
        return Icons.cancel;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ---------- Apply UI with File Upload ----------
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
                style: GoogleFonts.workSans(),
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
                Expanded(
                  child: Column(
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
                    'रु ${((double.tryParse(_monthlySalaryController.text) ?? 0) * 0.98).toStringAsFixed(0)}',
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

            // Monthly Salary
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
            const SizedBox(height: 32),

            // File Upload Section
            Text(
              'Document Upload',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // Salary Proof Upload
            _buildFileUploadCard(
              title: 'Salary Proof Document *',
              description:
                  'Upload your salary slip or bank statement (Required)',
              icon: Icons.receipt_long,
              file: _salaryProofFile,
              onUpload: () async {
                final file = await _pickImageFromGallery();
                if (file != null) {
                  setState(() => _salaryProofFile = file);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Salary proof selected successfully'),
                    ),
                  );
                }
              },
              onRemove: () => setState(() => _salaryProofFile = null),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Consent Form Upload
            _buildFileUploadCard(
              title: 'Consent Form',
              description:
                  'Upload signed consent form for salary deduction (Optional)',
              icon: Icons.assignment,
              file: _consentFile,
              onUpload: () async {
                final file = await _pickImageFromGallery();
                if (file != null) {
                  setState(() => _consentFile = file);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consent form selected successfully'),
                    ),
                  );
                }
              },
              onRemove: () => setState(() => _consentFile = null),
              isRequired: false,
            ),
            const SizedBox(height: 32),

            // Calculate Loan Details
            if (_monthlySalaryController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Calculation',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Eligible Amount:',
                          style: GoogleFonts.workSans(fontSize: 14),
                        ),
                        Text(
                          'रु ${((double.tryParse(_monthlySalaryController.text) ?? 0) * 0.98).toStringAsFixed(0)}',
                          style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Loan Amount:',
                          style: GoogleFonts.workSans(fontSize: 14),
                        ),
                        Text(
                          'रु ${(((double.tryParse(_monthlySalaryController.text) ?? 0) * 0.98) * _selectedDurationMonths).toStringAsFixed(0)}',
                          style: GoogleFonts.workSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _validateAndSubmitLoan(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
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

  void _validateAndSubmitLoan() {
    final salary = double.tryParse(_monthlySalaryController.text) ?? 0;
    final duration = _selectedDurationMonths;
    final reason = _loanPurposeController.text.trim();

    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly salary')),
      );
      return;
    }

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select loan duration')),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the purpose of loan')),
      );
      return;
    }

    if (_salaryProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload salary proof document')),
      );
      return;
    }

    _applyForLoanToService(
      monthlySalary: salary,
      durationMonths: duration,
      reason: reason,
      salaryProof: _salaryProofFile,
      consentFile: _consentFile,
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String description,
    required IconData icon,
    required XFile? file,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    required bool isRequired,
  }) {
    final bool hasFile = file != null;
    final Color borderColor = hasFile
        ? Colors.green.shade300
        : (isRequired ? Colors.orange.shade300 : Colors.grey.shade300);
    final Color bgColor = hasFile
        ? Colors.green.shade50
        : (isRequired ? Colors.orange.shade50 : Colors.grey.shade50);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: bgColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasFile
                      ? Colors.green.shade100
                      : (isRequired
                            ? Colors.orange.shade100
                            : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: hasFile
                      ? Colors.green.shade600
                      : (isRequired
                            ? Colors.orange.shade600
                            : Colors.grey.shade600),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                      description,
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFile) ...[
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, color: Colors.red.shade600),
                  tooltip: 'Remove file',
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasFile
                      ? Colors.green.shade600
                      : Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                icon: Icon(hasFile ? Icons.check : Icons.upload, size: 16),
                label: Text(hasFile ? 'Uploaded' : 'Upload'),
              ),
            ],
          ),
          if (hasFile) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'File selected: ${file.path.split('/').last}',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
              width: 2,
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

  // ---------- KYC Content ----------
  Widget _buildKYCContent() {
    // Pre-fill form if KYC data exists
    if (_kyc != null) {
      _fullNameController.text = _kyc!.fullName;
      _phoneController.text = _kyc!.phone;
      _panController.text = _kyc!.citizenshipNumber;
      _dobController.text = _kyc!.dateOfBirth;
    }

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
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Continuation of the _buildKYCContent method and remaining methods
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _kyc?.verified == true
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : _kyc != null
                      ? [Colors.orange.shade50, Colors.orange.shade100]
                      : [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kyc?.verified == true
                      ? Colors.green.shade200
                      : _kyc != null
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _kyc?.verified == true
                        ? Icons.check_circle
                        : _kyc != null
                        ? Icons.schedule
                        : Icons.info,
                    color: _kyc?.verified == true
                        ? Colors.green.shade600
                        : _kyc != null
                        ? Colors.orange.shade600
                        : Colors.blue.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _kyc?.verified == true
                        ? 'KYC Verified'
                        : _kyc != null
                        ? 'KYC Under Review'
                        : 'KYC Required',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kyc?.verified == true
                          ? Colors.green.shade700
                          : _kyc != null
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    _kyc?.verified == true
                        ? 'Your identity has been verified successfully'
                        : _kyc != null
                        ? 'Your KYC is submitted and under admin review'
                        : 'Complete KYC to apply for loans',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: _kyc?.verified == true
                          ? Colors.green.shade600
                          : _kyc != null
                          ? Colors.orange.shade600
                          : Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            if (_kyc?.verified != true) ...[
              const SizedBox(height: 32),
              Text(
                'Personal Information',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // Full Name
              _buildFormField(
                label: 'Full Name *',
                controller: _fullNameController,
                hint: 'Enter your full name as per citizenship',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildFormField(
                label: 'Phone Number *',
                controller: _phoneController,
                hint: 'Enter your phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Date of Birth
              _buildFormField(
                label: 'Date of Birth *',
                controller: _dobController,
                hint: 'YYYY-MM-DD',
                icon: Icons.calendar_today,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 6570),
                    ), // 18 years ago
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dobController.text = _formatDate(date);
                  }
                },
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Citizenship Number
              _buildFormField(
                label: 'Citizenship Number *',
                controller: _panController,
                hint: 'Enter your citizenship number',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 24),

              // Citizenship Photo Upload
              Text(
                'Document Upload',
                style: GoogleFonts.workSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              _buildFileUploadCard(
                title: 'Citizenship Photo *',
                description:
                    'Upload a clear photo of your citizenship certificate',
                icon: Icons.camera_alt,
                file: _citizenshipFile,
                onUpload: () async {
                  final file = await _pickImageFromGallery();
                  if (file != null) {
                    setState(() => _citizenshipFile = file);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Citizenship photo selected'),
                      ),
                    );
                  }
                },
                onRemove: () => setState(() => _citizenshipFile = null),
                isRequired: true,
              ),
              const SizedBox(height: 32),

              // Submit KYC Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _validateAndSubmitKYC,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _kyc != null ? 'Update KYC' : 'Submit KYC',
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

  void _validateAndSubmitKYC() {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final dob = _dobController.text.trim();
    final pan = _panController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    if (dob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    if (pan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your citizenship number')),
      );
      return;
    }

    if (_citizenshipFile == null &&
        _kyc?.citizenshipPhotoUrl.isEmpty != false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload citizenship photo')),
      );
      return;
    }

    _submitKYCToService(
      fullName: fullName,
      phone: phone,
      dateOfBirth: dob,
      citizenshipNumber: pan,
      citizenshipFile: _citizenshipFile,
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.workSans(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ---------- Profile Content ----------
  Widget _buildProfileContent() {
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _kyc?.verified == true
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _kyc?.verified == true ? 'Verified' : 'Unverified',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kyc?.verified == true
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Account Information',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileInfoCard('Email', _email(), Icons.email),
            const SizedBox(height: 12),
            _buildProfileInfoCard(
              'KYC Status',
              _kyc?.verified == true ? 'Verified' : 'Not Verified',
              Icons.verified_user,
            ),
            if (_kyc != null) ...[
              const SizedBox(height: 12),
              _buildProfileInfoCard('Full Name', _kyc!.fullName, Icons.person),
              const SizedBox(height: 12),
              _buildProfileInfoCard('Phone', _kyc!.phone, Icons.phone),
              const SizedBox(height: 12),
              _buildProfileInfoCard(
                'Date of Birth',
                _kyc!.dateOfBirth,
                Icons.cake,
              ),
              const SizedBox(height: 12),
              _buildProfileInfoCard(
                'Citizenship Number',
                _kyc!.citizenshipNumber,
                Icons.credit_card,
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Loan Summary',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Loans',
                    _loans.length.toString(),
                    Icons.credit_card,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Active Loans',
                    _loans
                        .where((l) => l.status.toLowerCase() == 'active')
                        .length
                        .toString(),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.workSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Settings Content ----------
  Widget _buildSettingsContent() {
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
            Text(
              'Application Settings',
              style: GoogleFonts.workSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 32),
            _buildSettingsSection('Account', [
              _buildSettingsItem(
                'Change Password',
                'Update your account password',
                Icons.lock,
                () {},
              ),
              _buildSettingsItem(
                'Privacy Settings',
                'Manage your privacy preferences',
                Icons.privacy_tip,
                () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection('Notifications', [
              _buildSettingsItem(
                'Push Notifications',
                'Manage push notification settings',
                Icons.notifications,
                () {},
              ),
              _buildSettingsItem(
                'Email Notifications',
                'Control email notification preferences',
                Icons.email,
                () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection('Support', [
              _buildSettingsItem(
                'Help Center',
                'Get help and support',
                Icons.help,
                () => setState(() => _selectedIndex = 6),
              ),
              _buildSettingsItem(
                'Terms of Service',
                'Read our terms and conditions',
                Icons.description,
                () {},
              ),
              _buildSettingsItem(
                'Privacy Policy',
                'View our privacy policy',
                Icons.shield,
                () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.workSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Colors.grey.shade600),
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
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Help Content ----------
  Widget _buildHelpContent() {
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
            Text(
              'Help & Support',
              style: GoogleFonts.workSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 32),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Support',
                    style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Text(
                        '+977-1-4444444',
                        style: GoogleFonts.workSans(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'support@payadvance.com',
                        style: GoogleFonts.workSans(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            _buildFAQItem(
              'How do I apply for a loan?',
              'Complete your KYC verification first, then navigate to the "Apply Loan" section and fill out the application form with required documents.',
            ),
            _buildFAQItem(
              'What documents are required for KYC?',
              'You need to provide your full name, phone number, date of birth, citizenship number, and upload a clear photo of your citizenship certificate.',
            ),
            _buildFAQItem(
              'How long does loan approval take?',
              'Loan approval typically takes 1-3 business days after submitting your complete application with all required documents.',
            ),
            _buildFAQItem(
              'What is the maximum loan amount?',
              'You can borrow up to 98% of your monthly salary. The exact amount depends on your salary verification.',
            ),
            _buildFAQItem(
              'How is the loan repaid?',
              'The loan amount is automatically deducted from your monthly salary as per the agreed terms.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Logout Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.workSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.workSans(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out', style: GoogleFonts.workSans()),
          ),
        ],
      ),
    );
  }
}
