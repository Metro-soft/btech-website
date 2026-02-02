import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/application_service.dart';
import '../../../core/network/auth_service.dart';

class StaffTaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> applicationData;

  const StaffTaskDetailScreen({super.key, required this.applicationData});

  @override
  State<StaffTaskDetailScreen> createState() => _StaffTaskDetailScreenState();
}

class _StaffTaskDetailScreenState extends State<StaffTaskDetailScreen> {
  // --- Theme Colors ---
  static const bgColor = Color(0xFF021024);
  static const cardColor = Color(0xFF052659);
  static const primaryText = Color(0xFFC1E8FF);
  static const secondaryText = Color(0xFF7DA0CA);
  static const errorColor = Color(0xFFCF6679);
  static const successColor = Color(0xFF4CAF50);

  // --- State ---
  late Map<String, dynamic> _appData;
  final ApplicationService _appService = ApplicationService();
  bool _isLoading = false;

  final Map<String, bool> _checklist = {
    'Verified Identity Documents': false,
    'Confirmed Payment Details': false,
    'Cross-checked with Official Database': false,
    'Generated Receipt/Certificate': false,
  };

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appData = widget.applicationData;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _assignToSelf() async {
    setState(() => _isLoading = true);
    try {
      // get current user name? backend logic uses name.
      // Ideally we fetch profile or auth service has it.
      // For now, let's assume we pass the current user's name or backend handles it?
      // Backend: req.body.staffName.
      // We need to fetch it.
      final user = await AuthService().getCurrentUser();

      final userId = user['id'];
      if (userId == null) {
        throw Exception('User ID not found. Please re-login.');
      }

      await _appService.assignTask(
        applicationId: _appData['_id'],
        staffId: userId,
      );

      // Refresh local data
      setState(() {
        _appData['status'] = 'ASSIGNED';
        _appData['assignedTo'] = user['name'];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task assigned to you!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTask() async {
    setState(() => _isLoading = true);
    try {
      await _appService.completeTask(applicationId: _appData['_id']);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task Completed!')));
        context.pop(); // Return to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectTask() async {
    // Show dialog to get reason
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Reject Application',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: TextStyle(color: secondaryText),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: secondaryText)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                await _appService.rejectTask(
                    applicationId: _appData['_id'],
                    reason: reasonController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task Rejected')));
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Reject', style: TextStyle(color: errorColor)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Process Application',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryText))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Client Summary Card
                  _buildClientSummaryCard(),
                  const SizedBox(height: 24),

                  // 2. Submitted Data
                  _buildDetailSection(
                    title: 'Client Details',
                    child: _buildDataGrid(),
                  ),
                  const SizedBox(height: 24),

                  // 3. Status-Based Content
                  if (_appData['assignedTo'] != null) ...[
                    // Checklist
                    _buildDetailSection(
                      title: 'Processing Checklist',
                      child: Column(
                        children: _checklist.keys.map((key) {
                          return Theme(
                            data:
                                ThemeData(unselectedWidgetColor: secondaryText),
                            child: CheckboxListTile(
                              activeColor: successColor,
                              checkColor: Colors.white,
                              title: Text(
                                key,
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 14),
                              ),
                              value: _checklist[key],
                              onChanged: (val) {
                                setState(() {
                                  _checklist[key] = val ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upload
                    _buildUploadSection(),
                    const SizedBox(height: 24),

                    // Comments
                    _buildDetailSection(
                      title: 'Staff Comments',
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add internal notes or feedback...',
                          hintStyle: TextStyle(
                              color: secondaryText.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Center(
                      child: Text(
                        'Please assign this task to yourself to start processing.',
                        style: GoogleFonts.poppins(color: secondaryText),
                      ),
                    ),

                  const SizedBox(height: 100), // Spacement for footer
                ],
              ),
            ),
      bottomSheet: _isLoading ? null : _buildFooter(context),
    );
  }

  Widget _buildClientSummaryCard() {
    final payload = _appData['payload'] ?? {};
    final clientName = payload['fullName'] ?? 'Client';
    final serviceType = _appData['type'] ?? 'Service';
    final appId = _appData['_id'].toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: bgColor,
            child: Text(
              clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
              style: GoogleFonts.poppins(
                  color: primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ...${appId.substring(appId.length - 6)}',
                  style:
                      GoogleFonts.poppins(color: secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    serviceType,
                    style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                color: secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    final payload = _appData['payload'] as Map<String, dynamic>? ?? {};

    // Filter out minimal non-display fields if any, or just show all
    final displayData = Map<String, dynamic>.from(payload);
    // Remove complex objects for now if any
    displayData.removeWhere(
        (key, value) => value is! String && value is! num && value is! bool);

    if (displayData.isEmpty) {
      return const Text('No additional details provided.',
          style: TextStyle(color: Colors.white));
    }

    return Column(
      children: displayData.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: GoogleFonts.poppins(color: secondaryText, fontSize: 14),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: secondaryText, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: primaryText, size: 40),
          const SizedBox(height: 12),
          Text(
            'Upload Generated Document',
            style: GoogleFonts.poppins(
                color: primaryText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            'Limit 5MB • PDF, JPG',
            style: GoogleFonts.poppins(color: secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (_appData['status'] == 'COMPLETED' || _appData['status'] == 'REJECTED') {
      return const SizedBox.shrink(); // Hide footer if done
    }

    final isAssigned = _appData['assignedTo'] != null;

    return Container(
      padding: const EdgeInsets.all(20),
      color: bgColor,
      child: isAssigned
          ? Row(
              children: [
                // Reject Button
                OutlinedButton(
                  onPressed: _rejectTask,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: errorColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.poppins(
                        color: errorColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                // Complete Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    child: Text(
                      'Complete Task',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _assignToSelf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryText,
                  foregroundColor: bgColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                ),
                child: Text(
                  'Start Processing (Assign to Self)',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
    );
  }
}
