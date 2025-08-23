// lib/presentation/screens/admin_user_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_project/core/models/kyc_model.dart';
import 'package:loan_project/core/models/loan_model.dart';
import 'package:loan_project/core/models/user_model.dart';
import 'package:loan_project/core/services/admin_dashboard_services.dart';

class AdminUserDetailsPage extends StatefulWidget {
  final String userId;

  const AdminUserDetailsPage({super.key, required this.userId});

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  final AdminDashboardServices _adminService = AdminDashboardServices();

  bool _loading = true;
  UserModel? _user;
  KYCModel? _kyc;
  List<LoanModel> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _loading = true);

    try {
      final details = await _adminService.getUserDetailsComplete(widget.userId);
      if (details != null && mounted) {
        setState(() {
          _user = details['user'] as UserModel?;
          _kyc = details['kyc'] as KYCModel?;
          _loans = details['loans'] as List<LoanModel>? ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'User Details',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'make_admin':
                  _showRoleChangeDialog('admin');
                  break;
                case 'make_user':
                  _showRoleChangeDialog('user');
                  break;
                case 'send_notification':
                  _showSendNotificationDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_user?.role != 'admin')
                PopupMenuItem(
                  value: 'make_admin',
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 18),
                      const SizedBox(width: 8),
                      Text('Make Admin', style: GoogleFonts.workSans()),
                    ],
                  ),
                ),
              if (_user?.role != 'user')
                PopupMenuItem(
                  value: 'make_user',
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      Text('Make User', style: GoogleFonts.workSans()),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'send_notification',
                child: Row(
                  children: [
                    const Icon(Icons.notifications, size: 18),
                    const SizedBox(width: 8),
                    Text('Send Notification', style: GoogleFonts.workSans()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? Center(
              child: Text(
                'User not found',
                style: GoogleFonts.workSans(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildUserOverviewCard(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUserInfoCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildKYCStatusCard()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildLoansHistoryCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildActivitySummaryCard()),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserOverviewCard() {
    final isAdmin = _user!.role.toLowerCase() == 'admin';
    final roleColor = isAdmin ? Colors.red : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(
              _user!.displayName.isNotEmpty
                  ? _user!.displayName[0]
                  : _user!.email[0],
              style: GoogleFonts.workSans(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _user!.displayName.isNotEmpty
                          ? _user!.displayName
                          : 'No Name',
                      style: GoogleFonts.workSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _user!.role.toUpperCase(),
                        style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _user!.email,
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Member since ${_formatDate(_user!.createdAt!)}',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
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

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('User ID', _user!.uid),
          _buildDetailRow(
            'Display Name',
            _user!.displayName.isNotEmpty ? _user!.displayName : 'Not set',
          ),
          _buildDetailRow('Email', _user!.email),
          _buildDetailRow('Role', _user!.role),
          _buildDetailRow(
            'Account Created',
            _formatDateTime(_user!.createdAt!),
          ),
          if (_user!.lastOnline != null)
            _buildDetailRow('Last Online', _formatDateTime(_user!.lastOnline!))
          else
            _buildDetailRow('Last Online', 'Never'),
        ],
      ),
    );
  }

  Widget _buildKYCStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KYC Status',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          if (_kyc != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kyc!.verified
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kyc!.verified
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _kyc!.verified ? Icons.verified_user : Icons.pending,
                        color: _kyc!.verified
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _kyc!.verified ? 'KYC Verified' : 'KYC Pending',
                        style: GoogleFonts.workSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kyc!.verified
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Full Name', _kyc!.fullName),
                  _buildDetailRow('Phone', _kyc!.phone),
                  _buildDetailRow('Date of Birth', _kyc!.dateOfBirth),
                  _buildDetailRow('Citizenship No.', _kyc!.citizenshipNumber),
                  _buildDetailRow(
                    'Submitted',
                    _formatDateTime(_kyc!.submittedAt!),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'KYC Not Submitted',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'User has not completed KYC verification',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoansHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loan History',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_loans.length} Total',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loans.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Loan Applications',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'User has not applied for any loans yet',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final loan = _loans[index];
                return _buildLoanCard(loan);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan) {
    final statusColor = _getStatusColor(loan.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(loan.status),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'रु ${loan.loanableAmount.toStringAsFixed(0)}',
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
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
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
                  '${loan.durationMonths} months • Applied ${_formatDate(loan.createdAt!)}',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (loan.reason.isNotEmpty)
                  Text(
                    'Purpose: ${loan.reason}',
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

  Widget _buildActivitySummaryCard() {
    final approvedLoans = _loans
        .where((loan) => loan.status == 'approved')
        .length;
    final pendingLoans = _loans
        .where((loan) => loan.status == 'pending')
        .length;
    final declinedLoans = _loans
        .where((loan) => loan.status == 'declined')
        .length;
    final totalLoanAmount = _loans
        .where((loan) => loan.status == 'approved')
        .fold(0.0, (sum, loan) => sum + loan.loanableAmount);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Summary',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryCard(
            'Approved Loans',
            approvedLoans.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Pending Loans',
            pendingLoans.toString(),
            Icons.schedule,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Declined Loans',
            declinedLoans.toString(),
            Icons.cancel,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Total Loan Amount',
            'रु ${totalLoanAmount.toStringAsFixed(0)}',
            Icons.account_balance,
            Colors.blue,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: Colors.purple.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'User Score',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _calculateUserScore().toString(),
                  style: GoogleFonts.workSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                Text(
                  'Based on KYC status and loan history',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.purple.shade600,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
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
                  value,
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
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

  int _calculateUserScore() {
    int score = 0;

    // Base score for having an account
    score += 20;

    // KYC bonus
    if (_kyc != null) {
      score += 30;
      if (_kyc!.verified) {
        score += 20;
      }
    }

    // Loan history bonus
    final approvedLoans = _loans
        .where((loan) => loan.status == 'approved')
        .length;
    final totalLoans = _loans.length;

    if (totalLoans > 0) {
      score += totalLoans * 5; // 5 points per loan application
      score += approvedLoans * 10; // Extra 10 points per approved loan

      // Bonus for good approval rate
      final approvalRate = totalLoans > 0 ? (approvedLoans / totalLoans) : 0;
      if (approvalRate >= 0.8) {
        score += 20;
      } else if (approvalRate >= 0.5) {
        score += 10;
      }
    }

    return score > 100 ? 100 : score;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  void _showRoleChangeDialog(String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change User Role',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to change ${_user!.displayName.isNotEmpty ? _user!.displayName : _user!.email}\'s role to ${newRole.toUpperCase()}?',
          style: GoogleFonts.workSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.workSans()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.updateUserRole(_user!.uid, newRole);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User role updated successfully'),
                    ),
                  );
                  _loadUserDetails(); // Reload to show updated data
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
            child: Text('Change Role', style: GoogleFonts.workSans()),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Notification',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send notification to ${_user!.displayName.isNotEmpty ? _user!.displayName : _user!.email}',
              style: GoogleFonts.workSans(),
            ),
            const SizedBox(height: 16),
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

              try {
                await _adminService.sendNotificationToUser(
                  userId: _user!.uid,
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  type: 'admin_message',
                );

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
}
