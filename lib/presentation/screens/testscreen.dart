import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  // Sample user data
  final Map<String, dynamic> userData = {
    'name': 'Ramesh Sharma',
    'email': 'ramesh.sharma@email.com',
    'phone': '+977-9841234567',
    'address': 'Kathmandu, Nepal',
    'monthlySalary': 75000.0,
    'currentLoan': 147000.0,
    'loanDuration': 2,
    'remainingMonths': 1,
    'eligibleAmount': 73500.0,
    'nextDeductionDate': '2025-09-01',
    'loanStatus': 'active',
    'kycStatus': 'verified',
    'joinDate': '2024-12-15',
  };

  // Form controllers
  final _loanAmountController = TextEditingController();
  final _loanPurposeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();

  final List<Map<String, dynamic>> notifications = [
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
      'message': 'Your loan of रु 1,47,000 has been approved successfully',
      'time': '3 days ago',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
    },
  ];

  final List<Map<String, dynamic>> loanHistory = [
    {
      'date': '2025-07-01',
      'amount': 147000.0,
      'status': 'Active',
      'duration': '2 months',
      'statusColor': Colors.orange,
    },
    {
      'date': '2025-05-15',
      'amount': 73500.0,
      'status': 'Completed',
      'duration': '1 month',
      'statusColor': Colors.green,
    },
    {
      'date': '2025-03-10',
      'amount': 110250.0,
      'status': 'Completed',
      'duration': '1.5 months',
      'statusColor': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main Content
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
                  'Welcome back, ${userData['name'].split(' ')[0]}',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Navigation
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
                  
                  // Logout button at bottom
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
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Content based on selected tab
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
                userData['name'][0],
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
      case 0: return 'Dashboard Overview';
      case 1: return 'My Loans';
      case 2: return 'Apply for Loan';
      case 3: return 'KYC Verification';
      case 4: return 'Profile Settings';
      case 5: return 'Settings';
      case 6: return 'Help & Support';
      default: return 'Dashboard';
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0: return 'Your financial overview at a glance';
      case 1: return 'Track your loan history and payments';
      case 2: return 'Get instant salary advance';
      case 3: return 'Complete your identity verification';
      case 4: return 'Manage your account information';
      case 5: return 'Customize your preferences';
      case 6: return 'Get help when you need it';
      default: return '';
    }
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0: return _buildOverviewContent();
      case 1: return _buildLoansContent();
      case 2: return _buildApplyContent();
      case 3: return _buildKYCContent();
      case 4: return _buildProfileContent();
      case 5: return _buildSettingsContent();
      case 6: return _buildHelpContent();
      default: return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Monthly Salary',
                  'रु ${userData['monthlySalary'].toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Available Loan',
                  'रु ${userData['eligibleAmount'].toStringAsFixed(0)}',
                  Icons.credit_card,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Loan',
                  'रु ${userData['currentLoan'].toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Remaining Months',
                  '${userData['remainingMonths']}',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Loan Progress & Quick Actions Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildLoanProgressCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickActionsCard()),
            ],
          ),
          const SizedBox(height: 24),

          // Notifications & Financial Tips
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                'Loan Amount: रु ${userData['currentLoan'].toStringAsFixed(0)}',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Next Deduction: ${userData['nextDeductionDate']}',
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
              widthFactor: 0.5, // 50% progress
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
            () => setState(() => _selectedIndex = 2),
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

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
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
              .map((notification) => _buildNotificationItem(notification)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: notification['color'].withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              notification['icon'],
              size: 16,
              color: notification['color'],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'],
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  notification['message'],
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  notification['time'],
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
                    value: 0.75, // 75% health score
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
            child: ListView.builder(
              itemCount: loanHistory.length,
              itemBuilder: (context, index) {
                final loan = loanHistory[index];
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
                          color: loan['statusColor'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          loan['status'] == 'Active'
                              ? Icons.schedule
                              : Icons.check_circle,
                          color: loan['statusColor'],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'रु ${loan['amount'].toStringAsFixed(0)}',
                              style: GoogleFonts.workSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              'Duration: ${loan['duration']}',
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Date: ${loan['date']}',
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
                          color: loan['statusColor'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          loan['status'],
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: loan['statusColor'],
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

  Widget _buildApplyContent() {
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
            // Header
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

            // Eligibility Card
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
                    'रु ${userData['eligibleAmount'].toStringAsFixed(0)}',
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

            // Application Form
            Text(
              'Application Details',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // Loan Amount
            _buildFormField(
              label: 'Loan Amount (रु)',
              controller: _loanAmountController,
              hint: 'Enter amount (Max: ${userData['eligibleAmount'].toStringAsFixed(0)})',
              icon: Icons.currency_rupee,
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

            // Duration Selection
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
                _buildDurationCard('1 Month', '1', true),
                const SizedBox(width: 12),
                _buildDurationCard('2 Months', '2', false),
                const SizedBox(width: 12),
                _buildDurationCard('3 Months', '3', false),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitLoanApplication,
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

  Widget _buildKYCContent() {
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
            // Header
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

            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: userData['kycStatus'] == 'verified'
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.orange.shade50, Colors.orange.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: userData['kycStatus'] == 'verified'
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    userData['kycStatus'] == 'verified'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: userData['kycStatus'] == 'verified'
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData['kycStatus'] == 'verified'
                        ? 'KYC Verified'
                        : 'KYC Pending',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: userData['kycStatus'] == 'verified'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    userData['kycStatus'] == 'verified'
                        ? 'Your identity has been successfully verified'
                        : 'Please complete the verification process',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: userData['kycStatus'] == 'verified'
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (userData['kycStatus'] != 'verified') ...[
              // KYC Form
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
                label: 'Address',
                controller: _addressController,
                hint: 'Enter your full address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'PAN Number',
                controller: _panController,
                hint: 'Enter your PAN number',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 32),

              // Document Upload
              Text(
                'Document Upload',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),

              _buildDocumentUpload('Citizenship/Passport', Icons.credit_card),
              const SizedBox(height: 16),
              _buildDocumentUpload('Photo', Icons.camera_alt),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitKYC,
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
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    userData['name'][0],
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
                        userData['name'],
                        style: GoogleFonts.workSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        userData['email'],
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

            // Profile Information
            _buildProfileSection('Personal Information', [
              _buildProfileItem('Full Name', userData['name'], Icons.person),
              _buildProfileItem('Email', userData['email'], Icons.email),
              _buildProfileItem('Phone', userData['phone'], Icons.phone),
              _buildProfileItem('Address', userData['address'], Icons.location_on),
            ]),
            const SizedBox(height: 24),

            _buildProfileSection('Employment Information', [
              _buildProfileItem('Monthly Salary', 'रु ${userData['monthlySalary'].toStringAsFixed(0)}', Icons.account_balance_wallet),
              _buildProfileItem('Join Date', userData['joinDate'], Icons.calendar_today),
              _buildProfileItem('KYC Status', userData['kycStatus'].toUpperCase(), Icons.verified_user),
            ]),
            const SizedBox(height: 24),

            _buildProfileSection('Loan Information', [
              _buildProfileItem('Eligible Amount', 'रु ${userData['eligibleAmount'].toStringAsFixed(0)}', Icons.credit_card),
              _buildProfileItem('Current Loan', 'रु ${userData['currentLoan'].toStringAsFixed(0)}', Icons.trending_up),
              _buildProfileItem('Loan Status', userData['loanStatus'].toUpperCase(), Icons.info),
            ]),
          ],
        ),
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

  // Helper Widgets
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

  Widget _buildDurationCard(String title, String value, bool isSelected) {
    return Expanded(
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
                color: isSelected ? Colors.orange.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
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
            onPressed: () {},
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

  Widget _buildSettingItem(String title, String subtitle, IconData icon, bool value) {
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

  Widget _buildSettingButton(String title, String subtitle, IconData icon, Color color) {
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

  Widget _buildHelpCard(String title, String subtitle, IconData icon, Color color) {
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

  // Action Methods
  void _submitLoanApplication() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loan application submitted successfully!',
          style: GoogleFonts.workSans(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _submitKYC() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'KYC submitted for verification!',
          style: GoogleFonts.workSans(),
        ),
        backgroundColor: Colors.blue,
      ),
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
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.workSans(),
              ),
            ),
          ],
        );
      },
    );
  }
}