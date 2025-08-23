// lib/presentation/screens/admin_dashboard.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_project/core/models/kyc_model.dart';
import 'package:loan_project/core/models/loan_model.dart';
import 'package:loan_project/core/models/user_model.dart';
import 'package:loan_project/core/services/admin_dashboard_services.dart';
import 'package:loan_project/core/services/auth_page_services.dart';
import 'package:loan_project/presentation/screens/admin_loan_details.dart';
import 'package:loan_project/presentation/screens/admin_kyc_details.dart';
import 'package:loan_project/presentation/screens/admin_user_details.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminDashboardServices _adminService = AdminDashboardServices();
  final AuthPageServices _authService = AuthPageServices();

  int _selectedIndex = 0;
  bool _loading = true;
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentActivities = [];

  // Stream controllers
  StreamSubscription<QuerySnapshot>? _loansSubscription;
  StreamSubscription<QuerySnapshot>? _kycSubscription;
  StreamSubscription<QuerySnapshot>? _usersSubscription;

  // Data
  List<LoanModel> _loans = [];
  List<KYCModel> _kycApplications = [];
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadData();
  }

  @override
  void dispose() {
    _loansSubscription?.cancel();
    _kycSubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminAndLoadData() async {
    setState(() => _loading = true);

    final isAdmin = await _adminService.isAdmin();
    if (isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
      return;
    }

    await _loadDashboardData();
    _setupStreamListeners();

    setState(() => _loading = false);
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await _adminService.getDashboardStats();
      final activities = await _adminService.getRecentActivities();

      setState(() {
        _dashboardStats = stats;
        _recentActivities = activities;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading dashboard data: $e');
    }
  }

  void _setupStreamListeners() {
    // Loans stream
    _loansSubscription = _adminService.getLoanApplicationsStream().listen((
      snapshot,
    ) {
      if (mounted) {
        setState(() {
          _loans = snapshot.docs
              .map(
                (doc) => LoanModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
      }
    });

    // KYC stream
    _kycSubscription = _adminService.getKYCApplicationsStream().listen((
      snapshot,
    ) {
      if (mounted) {
        setState(() {
          _kycApplications = snapshot.docs
              .map(
                (doc) => KYCModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
      }
    });

    // Users stream
    _usersSubscription = _adminService.getUsersStream().listen((snapshot) {
      if (mounted) {
        setState(() {
          _users = snapshot.docs
              .map(
                (doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: GoogleFonts.workSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          'PayAdvance',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNavItem(
                    0,
                    Icons.dashboard,
                    'Dashboard',
                    _dashboardStats['pendingLoans'] ?? 0,
                  ),
                  _buildNavItem(
                    1,
                    Icons.credit_card,
                    'Loan Management',
                    _loans.where((l) => l.status == 'pending').length,
                  ),
                  _buildNavItem(
                    2,
                    Icons.verified_user,
                    'KYC Management',
                    _kycApplications.where((k) => !k.verified).length,
                  ),
                  _buildNavItem(3, Icons.people, 'User Management', 0),
                  _buildNavItem(4, Icons.analytics, 'Analytics', 0),
                  _buildNavItem(5, Icons.notifications, 'Notifications', 0),
                  _buildNavItem(6, Icons.settings, 'Settings', 0),
                  const Spacer(),
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

  Widget _buildNavItem(int index, IconData icon, String title, int badgeCount) {
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
              color: isSelected ? Colors.red.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.red.shade700
                      : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: GoogleFonts.workSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                  if ((_dashboardStats['pendingLoans'] ?? 0) > 0)
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
              backgroundColor: Colors.red.shade100,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.red.shade700,
                size: 20,
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
        return 'Dashboard';
      case 1:
        return 'Loan Management';
      case 2:
        return 'KYC Management';
      case 3:
        return 'User Management';
      case 4:
        return 'Analytics';
      case 5:
        return 'Notifications';
      case 6:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Overview of system activities and statistics';
      case 1:
        return 'Manage loan applications and approvals';
      case 2:
        return 'Review and verify KYC documents';
      case 3:
        return 'Manage user accounts and permissions';
      case 4:
        return 'View detailed analytics and reports';
      case 5:
        return 'Send notifications to users';
      case 6:
        return 'System settings and configuration';
      default:
        return '';
    }
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildLoanManagementContent();
      case 2:
        return _buildKYCManagementContent();
      case 3:
        return _buildUserManagementContent();
      case 4:
        return _buildAnalyticsContent();
      case 5:
        return _buildNotificationsContent();
      case 6:
        return _buildSettingsContent();
      default:
        return _buildDashboardContent();
    }
  }

  // ---------- Dashboard Content ----------
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  _dashboardStats['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                  '+${_dashboardStats['newUsersThisMonth'] ?? 0} this month',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Loans',
                  _dashboardStats['totalLoans']?.toString() ?? '0',
                  Icons.credit_card,
                  Colors.green,
                  '+${_dashboardStats['newLoansThisWeek'] ?? 0} this week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Loans',
                  _dashboardStats['activeLoans']?.toString() ?? '0',
                  Icons.trending_up,
                  Colors.orange,
                  'Currently active',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pending Approvals',
                  (_dashboardStats['pendingLoans'] ??
                          0 + _dashboardStats['pendingKYC'] ??
                          0)
                      .toString(),
                  Icons.pending,
                  Colors.red,
                  'Requires action',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Secondary Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Loan Amount',
                  'रु ${(_dashboardStats['totalLoanAmount'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.account_balance,
                  Colors.purple,
                  'Outstanding amount',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Verified KYC',
                  _dashboardStats['verifiedKYC']?.toString() ?? '0',
                  Icons.verified_user,
                  Colors.teal,
                  '${_dashboardStats['pendingKYC'] ?? 0} pending',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pending Loans',
                  _dashboardStats['pendingLoans']?.toString() ?? '0',
                  Icons.schedule,
                  Colors.amber,
                  'Awaiting review',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '${_calculateSuccessRate()}%',
                  Icons.check_circle,
                  Colors.green,
                  'Approval rate',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activities and Quick Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentActivitiesCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickActionsCard()),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateSuccessRate() {
    final total = _dashboardStats['totalLoans'] ?? 0;
    final approved = _dashboardStats['activeLoans'] ?? 0;
    if (total == 0) return 0;
    return ((approved / total) * 100).round();
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
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
            value,
            style: GoogleFonts.workSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.workSans(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
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
                'Recent Activities',
                style: GoogleFonts.workSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: () {}, // Implement view all
                child: Text(
                  'View All',
                  style: GoogleFonts.workSans(color: Colors.red.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No recent activities',
                  style: GoogleFonts.workSans(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.take(5).length,
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                return _buildActivityItem(activity);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final status = activity['status'] as String;

    IconData icon;
    Color color;

    switch (type) {
      case 'loan':
        icon = Icons.credit_card;
        color = status == 'approved'
            ? Colors.green
            : status == 'declined'
            ? Colors.red
            : Colors.orange;
        break;
      case 'kyc':
        icon = Icons.verified_user;
        color = status == 'verified' ? Colors.green : Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

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
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  activity['description'] as String,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (activity['createdAt'] != null)
                  Text(
                    _formatDateTime(activity['createdAt'] as DateTime),
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.workSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          _buildQuickActionButton(
            'Review Pending Loans',
            Icons.rate_review,
            Colors.orange,
            () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Verify KYC Documents',
            Icons.verified_user,
            Colors.blue,
            () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Send Notification',
            Icons.notifications,
            Colors.green,
            () => setState(() => _selectedIndex = 5),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'View Analytics',
            Icons.analytics,
            Colors.purple,
            () => setState(() => _selectedIndex = 4),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Manage Users',
            Icons.people,
            Colors.teal,
            () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
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

  // ---------- Loan Management Content ----------
  Widget _buildLoanManagementContent() {
    final pendingLoans = _loans
        .where((loan) => loan.status == 'pending')
        .toList();
    final approvedLoans = _loans
        .where((loan) => loan.status == 'approved')
        .toList();
    final declinedLoans = _loans
        .where((loan) => loan.status == 'declined')
        .toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: TabBar(
              tabs: [
                Tab(text: 'All (${_loans.length})'),
                Tab(text: 'Pending (${pendingLoans.length})'),
                Tab(text: 'Approved (${approvedLoans.length})'),
                Tab(text: 'Declined (${declinedLoans.length})'),
              ],
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildLoansList(_loans),
                _buildLoansList(pendingLoans),
                _buildLoansList(approvedLoans),
                _buildLoansList(declinedLoans),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansList(List<LoanModel> loans) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No loans found',
              style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: ListView.builder(
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];
          return _buildLoanCard(loan);
        },
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan) {
    final statusColor = _getStatusColor(loan.status);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
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
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'रु ${loan.loanableAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.workSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        loan.status.toUpperCase(),
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${loan.durationMonths} months • Salary: रु${loan.monthlySalary.toStringAsFixed(0)}',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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
                Text(
                  'Applied: ${loan.createdAt != null ? _formatDateTime(loan.createdAt!) : 'N/A'}',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _viewLoanDetails(loan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.workSans(fontSize: 12),
                ),
              ),
              if (loan.status == 'pending') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showApprovalDialog(loan, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.workSans(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => _showApprovalDialog(loan, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.workSans(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- KYC Management Content ----------
  Widget _buildKYCManagementContent() {
    final pendingKYC = _kycApplications.where((kyc) => !kyc.verified).toList();
    final verifiedKYC = _kycApplications.where((kyc) => kyc.verified).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: TabBar(
              tabs: [
                Tab(text: 'All (${_kycApplications.length})'),
                Tab(text: 'Pending (${pendingKYC.length})'),
                Tab(text: 'Verified (${verifiedKYC.length})'),
              ],
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildKYCList(_kycApplications),
                _buildKYCList(pendingKYC),
                _buildKYCList(verifiedKYC),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKYCList(List<KYCModel> kycList) {
    if (kycList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No KYC applications found',
              style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: ListView.builder(
        itemCount: kycList.length,
        itemBuilder: (context, index) {
          final kyc = kycList[index];
          return _buildKYCCard(kyc);
        },
      ),
    );
  }

  Widget _buildKYCCard(KYCModel kyc) {
    final statusColor = kyc.verified ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
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
              kyc.verified ? Icons.verified_user : Icons.pending,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      kyc.fullName,
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        kyc.verified ? 'VERIFIED' : 'PENDING',
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: ${kyc.phone}',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Citizenship: ${kyc.citizenshipNumber}',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  'Submitted: ${kyc.submittedAt != null ? _formatDateTime(kyc.submittedAt!) : 'N/A'}',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _viewKYCDetails(kyc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.workSans(fontSize: 12),
                ),
              ),
              if (!kyc.verified) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showKYCApprovalDialog(kyc, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Verify',
                        style: GoogleFonts.workSans(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => _showKYCApprovalDialog(kyc, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.workSans(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- User Management Content ----------
  Widget _buildUserManagementContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      // Implement search functionality
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement export functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: Text('Export', style: GoogleFonts.workSans()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: GoogleFonts.workSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isAdmin = user.role.toLowerCase() == 'admin';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isAdmin
                ? Colors.red.shade100
                : Colors.blue.shade100,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0] : user.email[0],
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.bold,
                color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'No Name',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAdmin
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Joined: ${user.createdAt != null ? _formatDateTime(user.createdAt!) : 'N/A'}',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (user.lastOnline != null)
                  Text(
                    'Last online: ${_formatDateTime(user.lastOnline!)}',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _viewUserDetails(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'View Details',
              style: GoogleFonts.workSans(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Analytics Content ----------
  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Loan Approval Rate',
                  '${_calculateSuccessRate()}%',
                  Icons.trending_up,
                  Colors.green,
                  'This month: +5%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Average Loan Amount',
                  'रु ${_calculateAverageLoanAmount()}',
                  Icons.account_balance,
                  Colors.blue,
                  'Per application',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'KYC Verification Rate',
                  '${_calculateKYCRate()}%',
                  Icons.verified_user,
                  Colors.teal,
                  'Total verified',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Active Users',
                  '${_users.length}',
                  Icons.people,
                  Colors.purple,
                  'Total registered',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts and Detailed Analytics would go here
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Analytics',
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Advanced analytics charts will be implemented here',
                        style: GoogleFonts.workSans(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Including loan trends, user growth, and financial metrics',
                        style: GoogleFonts.workSans(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
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
            value,
            style: GoogleFonts.workSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.workSans(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  // ---------- Notifications Content ----------
  Widget _buildNotificationsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Send Notification Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Notification',
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
                      child: _buildNotificationTypeCard(
                        'Individual',
                        'Send to specific user',
                        Icons.person,
                        Colors.blue,
                        () => _showSendNotificationDialog(false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNotificationTypeCard(
                        'Broadcast',
                        'Send to all users',
                        Icons.broadcast_on_personal,
                        Colors.orange,
                        () => _showSendNotificationDialog(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Notifications
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Notifications',
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Notification history will be shown here',
                        style: GoogleFonts.workSans(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.workSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Settings Content ----------
  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Settings',
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingsItem(
                  'Loan Configuration',
                  'Configure loan parameters and limits',
                  Icons.settings,
                  () {},
                ),
                _buildSettingsItem(
                  'User Roles',
                  'Manage user roles and permissions',
                  Icons.admin_panel_settings,
                  () {},
                ),
                _buildSettingsItem(
                  'Backup & Export',
                  'Backup system data and export reports',
                  Icons.backup,
                  () {},
                ),
                _buildSettingsItem(
                  'System Logs',
                  'View system logs and activities',
                  Icons.list_alt,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.grey.shade600),
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
                        description,
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

  // ---------- Helper Methods ----------
  String _calculateAverageLoanAmount() {
    if (_loans.isEmpty) return '0';
    final total = _loans.fold(0.0, (sum, loan) => sum + loan.loanableAmount);
    return (total / _loans.length).toStringAsFixed(0);
  }

  int _calculateKYCRate() {
    if (_kycApplications.isEmpty) return 0;
    final verified = _kycApplications.where((kyc) => kyc.verified).length;
    return ((verified / _kycApplications.length) * 100).round();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // ---------- Navigation Methods ----------
  void _viewLoanDetails(LoanModel loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminLoanDetailsPage(loanId: loan.id),
      ),
    );
  }

  void _viewKYCDetails(KYCModel kyc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminKYCDetailsPage(userId: kyc.uid),
      ),
    );
  }

  void _viewUserDetails(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserDetailsPage(userId: user.uid),
      ),
    );
  }

  // ---------- Action Methods ----------
  void _showApprovalDialog(LoanModel loan, bool isApproval) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApproval ? 'Approve Loan' : 'Decline Loan',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'रु ${loan.loanableAmount.toStringAsFixed(0)} for ${loan.durationMonths} months',
              style: GoogleFonts.workSans(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: isApproval
                    ? 'Approval reason...'
                    : 'Decline reason...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.workSans()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a comment')),
                );
                return;
              }

              try {
                if (isApproval) {
                  await _adminService.approveLoan(
                    loan.id,
                    commentController.text.trim(),
                  );
                } else {
                  await _adminService.declineLoan(
                    loan.id,
                    commentController.text.trim(),
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Loan ${isApproval ? 'approved' : 'declined'} successfully',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isApproval ? 'Approve' : 'Decline',
              style: GoogleFonts.workSans(),
            ),
          ),
        ],
      ),
    );
  }

  void _showKYCApprovalDialog(KYCModel kyc, bool isApproval) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApproval ? 'Verify KYC' : 'Decline KYC',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KYC for ${kyc.fullName}',
              style: GoogleFonts.workSans(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: isApproval
                    ? 'Verification notes...'
                    : 'Decline reason...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.workSans()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a comment')),
                );
                return;
              }

              try {
                if (isApproval) {
                  await _adminService.approveKYC(
                    kyc.uid,
                    commentController.text.trim(),
                  );
                } else {
                  await _adminService.declineKYC(
                    kyc.uid,
                    commentController.text.trim(),
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'KYC ${isApproval ? 'verified' : 'declined'} successfully',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isApproval ? 'Verify' : 'Decline',
              style: GoogleFonts.workSans(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationDialog(bool isBroadcast) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedUserId = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isBroadcast
              ? 'Send Broadcast Notification'
              : 'Send Individual Notification',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isBroadcast) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select User',
                  border: OutlineInputBorder(),
                ),
                items: _users
                    .map(
                      (user) => DropdownMenuItem(
                        value: user.uid,
                        child: Text('${user.displayName} (${user.email})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedUserId = value ?? '',
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.workSans()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              if (!isBroadcast && selectedUserId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a user')),
                );
                return;
              }

              try {
                if (isBroadcast) {
                  await _adminService.sendBroadcastNotification(
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    type: 'admin_broadcast',
                  );
                } else {
                  await _adminService.sendNotificationToUser(
                    userId: selectedUserId,
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    type: 'admin_message',
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification sent successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Send', style: GoogleFonts.workSans()),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out of the admin panel?',
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
              print('Sign out button pressed'); // Debug
              Navigator.pop(context);

              print('About to call signOut()'); // Debug
              await _authService.signOut();
              print('SignOut completed'); // Debug

              if (mounted) {
                print('Navigating to /auth'); // Debug
                Navigator.pushReplacementNamed(context, '/auth');
              } else {
                print('Widget not mounted, skipping navigation'); // Debug
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
