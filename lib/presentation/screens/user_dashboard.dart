import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

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

  // KYC file paths
  String? citizenshipFront;
  String? citizenshipBack;

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
                  'Welcome back, ${userData['name'].split(' ')[0]}',
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
                  _buildNavItem(2, Icons.verified_user_outlined, 'KYC'),
                  _buildNavItem(3, Icons.add_circle_outline, 'Apply Now'),
                  _buildNavItem(4, Icons.account_circle_outlined, 'Profile'),
                  _buildNavItem(5, Icons.help_outline, 'Help & Support'),
                  const Spacer(),
                  _buildNavItem(6, Icons.logout, 'Sign Out', isLogout: true),
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
        return 'KYC Verification';
      case 3:
        return 'Apply for Loan';
      case 4:
        return 'Profile Settings';
      case 5:
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
        return 'Complete your KYC to get verified';
      case 3:
        return 'Get instant salary advance';
      case 4:
        return 'Manage your account information';
      case 5:
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
        return _buildKycContent();
      case 3:
        return _buildApplyContent();
      case 4:
        return _buildProfileContent();
      case 5:
        return _buildHelpContent();
      default:
        return _buildOverviewContent();
    }
  }

  // --- KYC FORM ---
  Widget _buildKycContent() {
    return SingleChildScrollView(
      child: Container(
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
              'KYC Verification Form',
              style: GoogleFonts.workSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('Full Name'),
            const SizedBox(height: 16),
            _buildTextField('Date of Birth', hint: 'YYYY-MM-DD'),
            const SizedBox(height: 16),
            _buildTextField('Citizenship Number'),
            const SizedBox(height: 16),
            _buildTextField('Issue Date', hint: 'YYYY-MM-DD'),
            const SizedBox(height: 16),
            _buildTextField('Issue District'),
            const SizedBox(height: 16),
            _buildTextField('Address'),
            const SizedBox(height: 16),
            _buildTextField('Phone Number', hint: '+977-XXXXXXXXX'),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildFilePickerButton(
                  'Upload Citizenship Front',
                  true,
                  citizenshipFront,
                ),
                const SizedBox(width: 16),
                _buildFilePickerButton(
                  'Upload Citizenship Back',
                  false,
                  citizenshipBack,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {String? hint}) {
    return TextField(
      style: GoogleFonts.workSans(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildFilePickerButton(String title, bool isFront, String? filePath) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.image,
          );
          if (result != null) {
            setState(() {
              if (isFront) {
                citizenshipFront = result.files.single.path;
              } else {
                citizenshipBack = result.files.single.path;
              }
            });
          }
        },
        icon: const Icon(Icons.upload_file),
        label: Text(
          filePath != null ? 'Uploaded' : title,
          style: GoogleFonts.workSans(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.orange.shade600),
        ),
      ),
    );
  }

  // --- APPLY FORM ---
  Widget _buildApplyContent() {
    return SingleChildScrollView(
      child: Container(
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
              'Loan Application Form',
              style: GoogleFonts.workSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('Loan Amount'),
            const SizedBox(height: 16),
            _buildTextField('Purpose of Loan'),
            const SizedBox(height: 16),
            _buildTextField('Repayment Duration (months)'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit Loan Application',
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

  // --- EXISTING OVERVIEW, LOANS, PROFILE, HELP ---
  Widget _buildOverviewContent() {
    return const Center(child: Text('Overview Content here'));
  }

  Widget _buildLoansContent() {
    return const Center(child: Text('Loan History Content here'));
  }

  Widget _buildProfileContent() {
    return const Center(child: Text('Profile Settings will be here'));
  }

  Widget _buildHelpContent() {
    return const Center(child: Text('Help & Support will be here'));
  }
}
