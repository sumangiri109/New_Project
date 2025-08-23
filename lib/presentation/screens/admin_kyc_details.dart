// lib/presentation/screens/admin_kyc_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_project/core/models/kyc_model.dart';
import 'package:loan_project/core/models/user_model.dart';
import 'package:loan_project/core/services/admin_dashboard_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminKYCDetailsPage extends StatefulWidget {
  final String userId;

  const AdminKYCDetailsPage({super.key, required this.userId});

  @override
  State<AdminKYCDetailsPage> createState() => _AdminKYCDetailsPageState();
}

class _AdminKYCDetailsPageState extends State<AdminKYCDetailsPage> {
  final AdminDashboardServices _adminService = AdminDashboardServices();
  
  bool _loading = true;
  KYCModel? _kyc;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadKYCDetails();
  }

  Future<void> _loadKYCDetails() async {
    setState(() => _loading = true);
    
    try {
      final details = await _adminService.getKYCDetailsWithUser(widget.userId);
      if (details != null && mounted) {
        setState(() {
          _kyc = details['kyc'] as KYCModel?;
          _user = details['user'] as UserModel?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading KYC details: $e')),
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
          'KYC Verification Details',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        actions: [
          if (_kyc != null && !_kyc!.verified) ...[
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
              icon: const Icon(Icons.verified_user, color: Colors.green),
              label: Text(
                'Verify',
                style: GoogleFonts.workSans(color: Colors.green),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _kyc == null
              ? Center(
                  child: Text(
                    'KYC not found',
                    style: GoogleFonts.workSans(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildKYCOverviewCard(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildKYCDetailsCard()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildUserInfoCard()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDocumentCard()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildVerificationHistoryCard()),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKYCOverviewCard() {
    final statusColor = _kyc!.verified ? Colors.green : Colors.orange;
    
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
              _kyc!.verified ? Icons.verified_user : Icons.pending,
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
                      _kyc!.fullName,
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
                        _kyc!.verified ? 'VERIFIED' : 'PENDING',
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
                  'KYC Application for ${_kyc!.citizenshipNumber}',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Submitted on ${_formatDateTime(_kyc!.submittedAt!)}',
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

  Widget _buildKYCDetailsCard() {
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
            'Personal Information',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Full Name', _kyc!.fullName),
          _buildDetailRow('Phone Number', _kyc!.phone),
          _buildDetailRow('Date of Birth', _kyc!.dateOfBirth),
          _buildDetailRow('Citizenship Number', _kyc!.citizenshipNumber),
          _buildDetailRow('User ID', _kyc!.uid),
          _buildDetailRow('Verification Status', _kyc!.verified ? 'Verified' : 'Pending'),
          _buildDetailRow('Submitted At', _formatDateTime(_kyc!.submittedAt!)),
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
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Account',
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
            _buildDetailRow('Account Created', _formatDateTime(_user!.createdAt!)),
            _buildDetailRow('User Role', _user!.role.toUpperCase()),
            if (_user!.lastOnline != null)
              _buildDetailRow('Last Online', _formatDateTime(_user!.lastOnline!)),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'User account not found',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: Colors.red.shade800,
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

  Widget _buildDocumentCard() {
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
          if (_kyc!.citizenshipPhotoUrl.isNotEmpty) ...[
            _buildDocumentPreview(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDocument(_kyc!.citizenshipPhotoUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  'View Full Document',
                  style: GoogleFonts.workSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Document Uploaded',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Citizenship photo not provided',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
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

  Widget _buildDocumentPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _kyc!.citizenshipPhotoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerificationHistoryCard() {
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
            'Verification History',
            style: GoogleFonts.workSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'KYC Submitted',
            'User submitted KYC documents',
            Icons.upload,
            Colors.blue,
            _formatDateTime(_kyc!.submittedAt!),
            isFirst: true,
          ),
          if (_kyc!.verified)
            _buildTimelineItem(
              'KYC Verified',
              'Documents verified by admin',
              Icons.verified_user,
              Colors.green,
              'Verified by admin',
              isLast: true,
            )
          else
            _buildTimelineItem(
              'Pending Verification',
              'Awaiting admin review',
              Icons.schedule,
              Colors.orange,
              'In review',
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

  Widget _buildTimelineItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String time, {
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
                Text(
                  time,
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
          isApproval ? 'Verify KYC Application' : 'Decline KYC Application',
          style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KYC for ${_kyc!.fullName}',
              style: GoogleFonts.workSans(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Citizenship: ${_kyc!.citizenshipNumber}',
              style: GoogleFonts.workSans(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: isApproval ? 'Verification notes...' : 'Decline reason...',
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
                  await _adminService.approveKYC(_kyc!.uid, commentController.text.trim());
                } else {
                  await _adminService.declineKYC(_kyc!.uid, commentController.text.trim());
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to KYC management
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('KYC ${isApproval ? 'verified' : 'declined'} successfully'),
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
              isApproval ? 'Verify' : 'Decline',
              style: GoogleFonts.workSans(),
            ),
          ),
        ],
      ),
    );
  }
}