import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/application_service.dart';
import 'package:image_picker/image_picker.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final _responseController = TextEditingController();
  final _service = ApplicationService();
  bool _isSubmitting = false;
  late Map<String, dynamic> _appData;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _appData = widget.application;
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      final freshData =
          await _service.getApplicationById(_appData['_id'].toString());
      if (mounted) {
        setState(() {
          _appData = freshData;
        });
      }
    } catch (e) {
      debugPrint('Auto-refresh error: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.submitInput(
          applicationId: _appData['_id'], response: _responseController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Response submitted successfully')));
        setState(() {
          // Optimistic Update
          _appData['clientAction']['required'] = false;
          _appData['clientAction']['response'] = _responseController.text;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final picker = ImagePicker();
    // Allow user to pick image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Read bytes for Web
      final bytes = await image.readAsBytes();

      await _service.uploadFile(
        applicationId: _appData['_id'],
        fileBytes: bytes, // Web and Mobile (bytes work for both if read)
        fileName: image.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')));
        _refreshData(); // Force refresh to update state
        setState(() {
          _appData['clientAction']['required'] = false;
          // Optimistic update of response to URL or Placeholder
          _appData['clientAction']['response'] = '[Document Uploaded]';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final status = _appData['status'] ?? 'PENDING';
    final type = _appData['type'] ?? 'Service';
    final ticket = _appData['ticketNumber'] ??
        (_appData['_id']?.toString().substring(0, 8).toUpperCase() ?? '---');
    final date = _appData['createdAt'] != null
        ? DateFormat('MMMM d, yyyy')
            .format(DateTime.parse(_appData['createdAt']))
        : '---';

    final clientAction = _appData['clientAction'] ?? {};
    // Forced true for Design Review as per user request to 'see' the input
    final isActionRequired = clientAction['required'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Application #$ticket',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _buildDesktopLayout(
                  status, type, ticket, date, isActionRequired, clientAction);
            } else {
              return _buildMobileLayout(
                  status, type, ticket, date, isActionRequired, clientAction);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(String status, String type, String ticket,
      String date, bool isActionRequired, Map clientAction) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL (Fixed)
          Expanded(
            flex: 4, // 40%
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      100, // Approximate height minus padding/appbar
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(status, type, ticket),
                      const SizedBox(height: 24),
                      _buildApplicationDetails(type, date, ticket),
                      const SizedBox(height: 24),
                      // Verification Section (Desktop)
                      if (isActionRequired) ...[
                        _buildVerificationCard(isActionRequired, clientAction),
                        const SizedBox(height: 24),
                      ],
                      _buildSupportCard(),
                      const Spacer(),
                      if (status == 'COMPLETED') ...[
                        const SizedBox(height: 12),
                        _buildDownloadButton(),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),

          // RIGHT PANEL (Scrollable)
          Expanded(
            flex: 6, // 60%
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2035).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineContent(
                        status, date, isActionRequired, clientAction),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String status, String type, String ticket,
      String date, bool isActionRequired, Map clientAction) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(status, type, ticket),
          const SizedBox(height: 16),

          // Verification Section (Mobile - High Visibility)
          if (isActionRequired) ...[
            _buildVerificationCard(isActionRequired, clientAction),
            const SizedBox(height: 16),
          ],

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                const Spacer(flex: 1),
                _buildApplicationDetails(type, date, ticket),
                const Spacer(flex: 2),
              ],
            ),
          ),

          // FOOTER
          Column(
            children: [
              _buildSupportCard(),
              const SizedBox(height: 16),
              // View Progress Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showProgressSheet(
                      context, status, date, isActionRequired, clientAction),
                  icon: const Icon(Icons.timeline, size: 18),
                  label: Text('View Progress',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22354D),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              if (status == 'COMPLETED') ...[
                const SizedBox(height: 12),
                _buildDownloadButton(),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // HELPER WIDGETS

  Widget _buildHeader(String status, String type, String ticket) {
    Color baseColor = _getStatusColor(status);
    IconData serviceIcon = _getServiceIcon(type);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withValues(alpha: 0.2),
            const Color(0xFF0F2035).withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: baseColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Watermark
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(serviceIcon,
                  size: 180, color: baseColor.withValues(alpha: 0.05)),
            ),

            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: baseColor.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Icon(serviceIcon, size: 36, color: baseColor),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(status,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 12),
                        Text(type,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 32,
                                height: 1.1,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('#$ticket',
                            style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 16,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(bool isActionRequired, Map clientAction) {
    // Dynamic content based on action type
    final message = clientAction['message'] ?? 'Verification needed';
    final type = clientAction['type'] ?? 'text'; // 'text' or 'file'
    final isEmail = message.toString().toLowerCase().contains('email');
    final isPhone = message.toString().toLowerCase().contains('phone') ||
        message.toString().toLowerCase().contains('sms');

    final bool showTextInput = type == 'text';
    final bool showFileUpload = type == 'file';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152A42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.lock_clock_outlined,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action Required',
                        style: GoogleFonts.outfit(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Additional Verification',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Descriptive Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        isEmail
                            ? Icons.mark_email_unread_outlined
                            : (isPhone ? Icons.sms_outlined : Icons.security),
                        size: 20,
                        color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Where to find the code:',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style:
                      GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Text(
                  'Why is this needed?',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'This verification ensures that you authorized this application request. It protects your personal data from unauthorized access.',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Input Field (Only if text type)
          if (showTextInput) ...[
            Text('Enter Verification Code/Response',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _responseController,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, letterSpacing: 1),
              textAlign: TextAlign.center,
              // keyboardType: TextInputType.number, // Removed strict number enforcement for general text
              decoration: InputDecoration(
                counterText: "",
                hintText: 'Enter response...',
                hintStyle:
                    GoogleFonts.outfit(color: Colors.white24, letterSpacing: 1),
                filled: true,
                fillColor: const Color(0xFF021024),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.orange)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Upload Button (Only if file type)
          if (showFileUpload) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: Text('Upload Document',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button (Always visible)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitResponse,
              style: ElevatedButton.styleFrom(
                backgroundColor: showFileUpload && !_isSubmitting
                    ? Colors.green
                    : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      showFileUpload ? 'Complete Upload' : 'Verify & Proceed',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationDetails(String type, String date, String ticket) {
    final payload = _appData['payload'] as Map<String, dynamic>? ?? {};
    final displayData = Map<String, dynamic>.from(payload);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: Colors.blue.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 8),
              Text('APPLICATION DETAILS',
                  style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 20),
          if (displayData.isEmpty)
            Text('No additional details provided.',
                style: GoogleFonts.outfit(color: Colors.white30))
          else
            Column(
              children: displayData.entries.expand<Widget>((entry) {
                // Helper to check for meaningful data
                bool hasData(dynamic val) {
                  if (val == null) return false;
                  final s = val.toString().trim().toLowerCase();
                  return s.isNotEmpty && s != 'null';
                }

                if (entry.value is Map) {
                  final nestedMap = entry.value as Map;
                  return nestedMap.entries
                      .where((e) => hasData(e.value))
                      .map((nestedEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SecureDataRow(
                          label: nestedEntry.key.toString(),
                          value: nestedEntry.value.toString()),
                    );
                  });
                }

                if (!hasData(entry.value)) return <Widget>[];

                return [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SecureDataRow(
                        label: entry.key, value: entry.value.toString()),
                  )
                ];
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support unavailable')));
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headset_mic_outlined,
                  color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need assistance?',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('Tap to contact support',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _downloadDocuments,
        icon: const Icon(Icons.download),
        label: Text('Download Documents',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildTimelineContent(
      String status, String date, bool isActionRequired, Map clientAction) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tracking Timeline',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildTimelineStep(
          title: 'Application Submitted',
          subtitle: 'completed on $date',
          isActive: true,
          isFirst: true,
          isLast: false,
        ),
        _buildTimelineStep(
          title: 'Staff Review',
          subtitle: status == 'PENDING' ? 'Waiting for assignment' : 'Assigned',
          isActive: status != 'PENDING',
          isFirst: false,
          isLast: false,
        ),
        if (isActionRequired || clientAction['response'] != null)
          _buildTimelineStep(
            title: isActionRequired
                ? 'Verification Required'
                : 'Verification Provided',
            subtitle: isActionRequired
                ? 'Action needed: ${clientAction['message'] ?? 'Enter Code'}'
                : 'Code Submitted: ${clientAction['response']}',
            isActive: !isActionRequired,
            isColorOverride: isActionRequired ? Colors.orange : null,
            isFirst: false,
            isLast: false,
          ),
        // Dynamic Processing Steps
        ...(_appData['processingSteps'] as List? ?? []).map<Widget>((step) {
          final isCompleted = step['completed'] == true;
          if (!isCompleted) {
            return const SizedBox.shrink();
          }
          // User wants "Tracking", so seeing completed steps is good.
          // Seeing pending steps might be too much info or good info (Transparency).
          // For now, let's show completed steps as active, and maybe not show pending to avoid clutter,
          // OR show pending as inactive.
          // Let's show COMPLETED items only to keep the timeline "Progress" focused.

          return _buildTimelineStep(
            title: step['step'] ?? 'Processing Step',
            subtitle: 'Verified by Staff',
            isActive: true,
            isFirst: false,
            isLast: false,
          );
        }),
        _buildTimelineStep(
          title: 'Processing at HQ',
          subtitle: isActionRequired
              ? 'Paused: Waiting for verification'
              : 'Review & Verification in progress',
          isActive: ['COMPLETED', 'REJECTED'].contains(status) ||
              (status == 'IN_PROGRESS' && !isActionRequired),
          isFirst: false,
          isLast: false,
        ),
        _buildTimelineStep(
          title: status == 'REJECTED' ? 'Application Rejected' : 'Complete',
          subtitle: status == 'COMPLETED'
              ? 'Ready for download'
              : (status == 'REJECTED'
                  ? 'Check email for details'
                  : 'Pending completion'),
          isActive: ['COMPLETED', 'REJECTED'].contains(status),
          isColorOverride: status == 'REJECTED' ? Colors.red : null,
          isFirst: false,
          isLast: true,
        ),
      ],
    );
  }

  void _showProgressSheet(BuildContext context, String status, String date,
      bool isActionRequired, Map clientAction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2035),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              _buildTimelineContent(
                  status, date, isActionRequired, clientAction),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadDocuments() async {
    try {
      final urlString = await _service.getDownloadUrl(_appData['_id']);
      final Uri url = Uri.parse(urlString);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch download link')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download Error: $e')));
      }
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isFirst,
    required bool isLast,
    Color? isColorOverride,
  }) {
    final color = isColorOverride ??
        (isActive ? const Color(0xFF4CAF50) : Colors.white12);
    final lineColor = isActive ? const Color(0xFF4CAF50) : Colors.white12;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: lineColor)),
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: isActive || isColorOverride != null
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8)
                          ]
                        : [],
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          color: isActive ? Colors.white : Colors.white24,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          color: isActive ? Colors.white70 : Colors.white12,
                          fontSize: 13)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getServiceIcon(String type) {
    if (type.contains('KRA')) return Icons.receipt_long;
    if (type.contains('eTA')) return Icons.flight_takeoff;
    if (type.contains('HELB')) return Icons.school;
    if (type.contains('Cyber')) return Icons.computer;
    return Icons.description;
  }
}

class _SecureDataRow extends StatefulWidget {
  final String label;
  final String value;

  const _SecureDataRow({required this.label, required this.value});

  @override
  State<_SecureDataRow> createState() => _SecureDataRowState();
}

class _SecureDataRowState extends State<_SecureDataRow> {
  static const secondaryText = Color(0xFF7DA0CA);

  bool _isVisible = false;

  bool get _isSensitive {
    final val = widget.value.toLowerCase().trim();
    if (val.isEmpty || val == 'null') return false;

    final key = widget.label.toLowerCase();
    return key.contains('password') ||
        key.contains('pin') ||
        key.contains('id') ||
        key.contains('phone') ||
        key.contains('email') ||
        key.contains('secret');
  }

  @override
  Widget build(BuildContext context) {
    // If not sensitive, just show plain text
    if (!_isSensitive) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label,
                style: GoogleFonts.outfit(color: secondaryText, fontSize: 12)),
            Expanded(
              child: SelectableText(
                widget.value,
                textAlign: TextAlign.end,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      );
    }

    // If sensitive, show shielded view
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Row(
            children: [
              Text(widget.label,
                  style:
                      GoogleFonts.outfit(color: secondaryText, fontSize: 12)),
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline, color: Colors.orange, size: 12),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isVisible)
                  Expanded(
                    child: SelectableText(
                      widget.value,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    '••••••••',
                    style: GoogleFonts.spaceMono(
                        color: Colors.white54,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _isVisible = !_isVisible),
                  child: Icon(
                    _isVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: widget.value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: "${widget.value}"'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.copy_all_outlined,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
