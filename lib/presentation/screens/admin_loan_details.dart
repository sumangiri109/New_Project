// lib/presentation/screens/admin_loan_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_project/core/models/kyc_model.dart';
import 'package:loan_project/core/models/loan_model.dart';
import 'package:loan_project/core/models/user_model.dart';
import 'package:loan_project/core/services/admin_dashboard_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminLoanDetailsPage extends StatefulWidget {
  final String loanId;

  const AdminLoanDetailsPage({super.key, required this.loanId});

  @override
  State<AdminLoanDetailsPage> createState() => _AdminLoanDetailsPageState();
}

class _AdminLoanDetailsPageState extends State<AdminLoanDetailsPage> {
  final AdminDashboardServices _adminService = AdminDashboardServices();
  
  bool _loading = true;
  LoanModel? _loan;
  UserModel? _user;
  KYCModel? _kyc;

  @override
  void initState() {
    super.initState();
    _loadLoanDetails();
  }

  Future<void> _loadLoanDetails() async {
    setState(() => _loading = true);
    
    try {
      final details = await _adminService.getLoanDetailsWithUser(widget.loanId);
      if (details != null && mounted) {
        setState(() {
          _loan = details['loan'] as LoanModel?;
          _user = details['user'] as UserModel?;
          _kyc = details['kyc'] as KYCModel?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading loan details: $e')),
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
          'Loan Application Details',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        actions: [
          if (_loan?.status == 'pending') ...[
            TextButton.icon(
              onPressed: () => _showActionDialog(false),
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: Text(
                'Decline',
                style: GoogleFonts.workSans(color: Colors.red),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showActionDialog(true),
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: Text(
                'Approve',
                style: GoogleFonts.workSans(color: Colors.green),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loan == null
              ? Center(
                  child: Text(
                    'Loan not found',
                    style: GoogleFonts.workSans(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildLoanOverviewCard(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildLoanDetailsCard()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildApplicantInfoCard()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDocumentsCard()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildActionHistoryCard()),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoanOverviewCard() {
    final statusColor = _getStatusColor(_loan!.status);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getStatusIcon(_loan!.status),
              color: statusColor,
              size: 40,
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
                      'रु ${_loan!.loanableAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.workSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _loan!.status.toUpperCase(),
                        style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Loan Application #${_loan!.id.substring(0, 8)}',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Applied on ${_formatDateTime(_loan!.createdAt!)}',
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

  Widget _buildLoanDetailsCard() {
    return Container(
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
            'Loan Details',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Monthly Salary', 'रु ${_loan!.monthlySalary.toStringAsFixed(0)}'),
          _buildDetailRow('Loan Duration', '${_loan!.durationMonths} months'),
          _buildDetailRow('Loanable Amount', 'रु ${_loan!.loanableAmount.toStringAsFixed(0)}'),
          _buildDetailRow('Monthly Deduction', 'रु ${(_loan!.loanableAmount / _loan!.durationMonths).toStringAsFixed(0)}'),
          _buildDetailRow('Application ID', _loan!.id),
          if (_loan!.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Purpose',
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _loan!.reason,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicantInfoCard() {
    return Container(
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
            'Applicant Information',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          if (_user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _user!.displayName.isNotEmpty ? _user!.displayName[0] : _user!.email[0],
                    style: GoogleFonts.workSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.displayName.isNotEmpty ? _user!.displayName : 'No Name',
                        style: GoogleFonts.workSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        _user!.email,
                        style: GoogleFonts.workSans(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_kyc != null) ...[
            _buildDetailRow('Full Name', _kyc!.fullName),
            _buildDetailRow('Phone', _kyc!.phone),
            _buildDetailRow('Date of Birth', _kyc!.dateOfBirth),
            _buildDetailRow('Citizenship No.', _kyc!.citizenshipNumber),
            _buildDetailRow('KYC Status', _kyc!.verified ? 'Verified' : 'Pending'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'KYC not submitted',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                      ),
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

  Widget _buildDocumentsCard() {
    return Container(
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
            'Documents',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          if (_loan!.salaryProofUrl.isNotEmpty)
            _buildDocumentItem(
              'Salary Proof',
              'View salary proof document',
              Icons.receipt_long,
              Colors.green,
              () => _openDocument(_loan!.salaryProofUrl),
            ),
          const SizedBox(height: 12),
          if (_loan!.consentUrl.isNotEmpty)
            _buildDocumentItem(
              'Consent Form',
              'View signed consent form',
              Icons.assignment,
              Colors.blue,
              () => _openDocument(_loan!.consentUrl),
            )
          else
            _buildDocumentItem(
              'Consent Form',
              'No consent form uploaded',
              Icons.assignment_outlined,
              Colors.grey,
              null,
            ),
          if (_kyc != null && _kyc!.citizenshipPhotoUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDocumentItem(
              'Citizenship Photo',
              'View citizenship document',
              Icons.credit_card,
              Colors.orange,
              () => _openDocument(_kyc!.citizenshipPhotoUrl),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionHistoryCard() {
    return Container(
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
            'Action History',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Application Submitted',
            _formatDateTime(_loan!.createdAt!),
            Icons.upload,
            Colors.blue,
            isFirst: true,
          ),
          if (_loan!.status != 'pending')
            _buildTimelineItem(
              _loan!.status == 'approved' ? 'Loan Approved' : 'Loan Declined',
              'Action taken by admin',
              _loan!.status == 'approved' ? Icons.check_circle : Icons.cancel,
              _loan!.status == 'approved' ? Colors.green : Colors.red,
              isLast: true,
            )
          else
            _buildTimelineItem(
              'Pending Review',
              'Awaiting admin action',
              Icons.schedule,
              Colors.orange,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.workSans(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String description,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey.shade300,
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'declined': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'declined': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  void _showActionDialog(bool isApproval) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApproval ? 'Approve Loan Application' : 'Decline Loan Application',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'रु ${_loan!.loanableAmount.toStringAsFixed(0)} for ${_loan!.durationMonths} months',
              style: GoogleFonts.workSans(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: isApproval ? 'Approval reason and notes...' : 'Decline reason...',
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
                  await _adminService.approveLoan(_loan!.id, commentController.text.trim());
                } else {
                  await _adminService.declineLoan(_loan!.id, commentController.text.trim());
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to loan management
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loan ${isApproval ? 'approved' : 'declined'} successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
}