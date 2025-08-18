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
    'monthlySalary': 75000.0,
    'currentLoan': 147000.0,
    'loanDuration': 2,
    'remainingMonths': 1,
    'eligibleAmount': 73500.0,
    'nextDeductionDate': '2025-09-01',
    'loanStatus': 'active',
  };

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLogout) {
              // Handle logout
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
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.grey.shade600,
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
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'View Documents',
            Icons.description_outlined,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Update Salary Info',
            Icons.edit_outlined,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Contact Support',
            Icons.support_agent,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
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
      child: const Center(child: Text('Loan Application Form will be here')),
    );
  }

  Widget _buildProfileContent() {
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
      child: const Center(child: Text('Profile Settings will be here')),
    );
  }

  Widget _buildHelpContent() {
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
      child: const Center(child: Text('Help & Support will be here')),
    );
  }
}
