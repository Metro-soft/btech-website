import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../data/staff_task_service.dart';
import '../../../core/network/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // --- Presets ---
  // Structure: 'Category': [{'label': 'Button Label', 'message': 'Actual Message to Client', 'type': 'text'|'file'}]
  static const Map<String, List<Map<String, String>>> verificationPresets = {
    'General': [
      {
        'label': 'Verify Email',
        'message': 'Please verify your email address to proceed.',
        'type': 'text'
      },
      {
        'label': 'Upload ID',
        'message': 'We need a copy of your ID to verify your identity.',
        'type': 'file'
      },
      {
        'label': 'Clarify Service',
        'message': 'Please clarify the service required.',
        'type': 'text'
      },
    ],
    'KRA': [
      {
        'label': 'Wrong Password',
        'message':
            'The KRA password provided is incorrect. Please provide the correct one.',
        'type': 'text'
      },
      {
        'label': 'OTP Required',
        'message':
            'Please provide the OTP sent to your registered KRA phone number.',
        'type': 'text'
      },
      {
        'label': 'Upload P9',
        'message': 'Please upload your P9 form for the year.',
        'type': 'file'
      },
      {
        'label': 'Upload ID Copy',
        'message': 'We need a copy of your National ID.',
        'type': 'file'
      },
    ],
    'eTA': [
      {
        'label': 'Passport Info',
        'message': 'Please provide your Passport Number and Expiry Date.',
        'type': 'text'
      },
      {
        'label': 'Upload Flight',
        'message': 'We need a copy of your Flight Itinerary.',
        'type': 'file'
      },
      {
        'label': 'Verify Hotel',
        'message': 'Please verify your Hotel Booking details.',
        'type': 'text'
      },
    ],
    'HELB': [
      {
        'label': 'Guardian Info',
        'message':
            'Please provide the phone number of your documented Guardian.',
        'type': 'text'
      },
      {
        'label': 'ID Serial',
        'message': 'Please provide your National ID Serial Number.',
        'type': 'text'
      },
      {
        'label': 'Upload Bank Slip',
        'message':
            'Please verify your bank account details by uploading a slip or statement.',
        'type': 'file'
      },
    ],
    'KUCCPS': [
      {
        'label': 'Index Number',
        'message': 'Please provide your Index Number.',
        'type': 'text'
      },
      {
        'label': 'Upload Results',
        'message': 'Please upload your Results Slip.',
        'type': 'file'
      },
      {
        'label': 'Program Choices',
        'message': 'Please clarify your preferred program choices.',
        'type': 'text'
      },
    ],
    'eINT': [
      {
        'label': 'Nature of Business',
        'message': 'Please describe the nature of your business.',
        'type': 'text'
      },
      {
        'label': 'Device Serial',
        'message': 'Please provide the Device Serial Number.',
        'type': 'text'
      }
    ]
  };

  // --- State ---
  late Map<String, dynamic> _appData;
  final StaffTaskService _appService = StaffTaskService();
  bool _isLoading = false;
  String? _authToken; // Store token for secure image fetching

  final Map<String, bool> _checklist = {
    'Verified Identity Documents': false,
    'Confirmed Payment Details': false,
    'Cross-checked with Official Database': false,
    'Generated Receipt/Certificate': false,
  };

  final TextEditingController _commentController = TextEditingController();
  Timer? _refreshTimer;
  // State for toggling sensitive data visibility
  bool _isSensitiveDataVisible = false;

  // Helper to handle legacy /uploads/ URLs by converting them to secure /api/files/view/
  String _getSecureUrl(String originalUrl) {
    if (originalUrl.contains('/uploads/')) {
      return originalUrl.replaceAll('/uploads/', '/api/files/view/');
    }
    return originalUrl;
  }

  @override
  void initState() {
    super.initState();
    _appData = widget.applicationData;
    _syncChecklist();
    _loadToken();
    _startAutoRefresh();
  }

  Future<void> _loadToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (mounted) {
      setState(() => _authToken = token);
    }
  }

  void _syncChecklist() {
    final steps = _appData['processingSteps'] as List?;
    if (steps != null) {
      for (var step in steps) {
        final key = step['step'];
        if (_checklist.containsKey(key)) {
          _checklist[key] = step['completed'] == true;
        }
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      final freshData =
          await _appService.getApplicationById(_appData['_id'].toString());
      if (mounted) {
        setState(() {
          _appData = freshData;
          _syncChecklist();
        });
      }
    } catch (e) {
      debugPrint('Auto-refresh error: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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

  Future<void> _requestAction() async {
    final messageController = TextEditingController();
    Map<String, String>? selectedPreset;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final type = _appData['type'] ?? 'General';
            // Get presets for this type, fallback to General
            final presets = verificationPresets.entries
                .firstWhere((e) => type.contains(e.key),
                    orElse: () => verificationPresets.entries.first)
                .value;

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Verification/Input',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Select a Preset:',
                      style: GoogleFonts.poppins(
                          color: secondaryText, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      final isSelected = selectedPreset == preset;
                      final type = preset['type'] == 'file' ? 'Upload' : 'Text';
                      return ActionChip(
                        backgroundColor: isSelected
                            ? Colors.orange
                            : bgColor.withValues(alpha: 0.5),
                        label: Text('${preset['label']} ($type)',
                            style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : primaryText,
                                fontSize: 11)),
                        onPressed: () {
                          setSheetState(() {
                            selectedPreset = preset;
                            messageController.text = preset['message'] ?? '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter specific instructions...',
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Pass back both message and type
                        Navigator.pop(sheetContext, {
                          'message': messageController.text,
                          'type': selectedPreset?['type'] ?? 'text'
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Send Request',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) async {
      if (result != null && result is Map) {
        setState(() => _isLoading = true);
        try {
          await _appService.requestInput(
            applicationId: _appData['_id'],
            message: result['message'],
            type: result['type'],
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request sent to client')));
            context.pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
            setState(() => _isLoading = false);
          }
        }
      }
    });
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Process Application',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryText))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return _buildDesktopLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL (Fixed: Summary, Details & Actions)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 32),
                  // Moved Details to Left
                  _buildSectionHeader('APPLICATION DETAILS'),
                  const SizedBox(height: 16),
                  _buildDetailView(),
                  const SizedBox(height: 16),
                  _buildClientResponseCard(),
                  const SizedBox(height: 32),
                  // Actions below details
                  if (_appData['assignedTo'] != null) ...[
                    _buildActionsCard(), // Only Request/Reject
                  ] else
                    _buildAssignmentCard(),
                  const SizedBox(height: 24),
                  _buildSupportCard(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),

          // RIGHT PANEL (Scrollable: Timeline & Work)
          Expanded(
            flex: 6,
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
                    if (_appData['assignedTo'] != null) ...[
                      _buildSectionHeader('PROCESSING TIMELINE'),
                      const SizedBox(height: 24),
                      _buildTimelineChecklist(),
                      const SizedBox(height: 32),
                      _buildUploadSection(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('INTERNAL NOTES'),
                      const SizedBox(height: 16),
                      _buildCommentSection(),
                      const SizedBox(height: 48),
                      // Moved Completion to Bottom Right
                      _buildCompletionAction(),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'Assign this task to yourself to view the checklist and processing tools.',
                            style: GoogleFonts.outfit(color: Colors.white30),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildDetailView(),
          const SizedBox(height: 12),
          _buildClientResponseCard(),
          const SizedBox(height: 24),
          if (_appData['assignedTo'] != null) ...[
            _buildSectionHeader('PROCESSING TIMELINE'),
            const SizedBox(height: 16),
            _buildTimelineChecklist(),
            const SizedBox(height: 24),
            _buildUploadSection(),
            const SizedBox(height: 24),
            _buildCommentSection(),
            const SizedBox(height: 24),
            _buildActionsCard(), // Inline actions for mobile
          ] else
            _buildAssignmentCard(),
          const SizedBox(height: 40),
          _buildSupportCard(),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: secondaryText),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final payload = _appData['payload'] ?? {};
    final clientName = payload['fullName'] ?? 'Client';
    final serviceType = _appData['type'] ?? 'Service';
    final appId = _appData['_id'].toString();
    final status = _appData['status'] ?? 'PENDING';

    Color baseColor = status == 'COMPLETED'
        ? successColor
        : (status == 'PENDING' ? Colors.orange : secondaryText);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withValues(alpha: 0.2),
            const Color(0xFF0F2035).withValues(alpha: 0.8),
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
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.folder_open,
                  size: 150, color: Colors.white.withValues(alpha: 0.03)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: baseColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.outfit(
                              color: baseColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '#${appId.substring(appId.length - 6).toUpperCase()}',
                        style: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white10,
                        child: Text(
                          clientName.isNotEmpty
                              ? clientName[0].toUpperCase()
                              : 'C',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clientName,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(serviceType,
                                style: GoogleFonts.outfit(
                                    color: secondaryText, fontSize: 14)),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildClientResponseCard() {
    final clientAction =
        _appData['clientAction'] as Map<String, dynamic>? ?? {};
    final response = clientAction['response'];
    final message = clientAction['message'] ?? 'Requested Information';

    if (response == null || response.toString().isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24), // Add margin for spacing
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
          Row(
            children: [
              const Icon(Icons.mark_chat_read_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Client Response',
                  style: GoogleFonts.outfit(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Your Request:',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          Text(message, style: GoogleFonts.outfit(color: Colors.white70)),
          const SizedBox(height: 16),
          Text('Client Replied:',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.3))),
            child: response.toString().startsWith('http')
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _authToken == null
                            ? Container(
                                height: 200,
                                color: Colors.white10,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Image.network(
                                _getSecureUrl(response.toString()),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                headers: {
                                  'Authorization': 'Bearer $_authToken'
                                },
                                errorBuilder: (c, e, s) {
                                  debugPrint('Image Load Error: $e');
                                  return Container(
                                      height: 200,
                                      color: Colors.white10,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image,
                                              color: Colors.white54),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Secure Image\n(Check Token/Network)',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.outfit(
                                                  color: Colors.white54,
                                                  fontSize: 10)),
                                        ],
                                      ));
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Image Source: Secure Viewer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10))),
                          // Removed External Launch Button as it would fail auth logs without token
                          // and violates "no download" policy.
                          const Icon(Icons.lock,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text('Protected',
                              style: GoogleFonts.outfit(
                                  color: Colors.orange, fontSize: 10))
                        ],
                      )
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            _isSensitiveDataVisible
                                ? response.toString()
                                : '•' *
                                    response.toString().length, // Mask logic
                            style: GoogleFonts.spaceMono(
                                color: _isSensitiveDataVisible
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 16,
                                letterSpacing: _isSensitiveDataVisible ? 0 : 2,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                              _isSensitiveDataVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white54,
                              size: 20),
                          tooltip: _isSensitiveDataVisible
                              ? 'Hide Data'
                              : 'Reveal Data',
                          onPressed: () {
                            setState(() {
                              _isSensitiveDataVisible =
                                  !_isSensitiveDataVisible;
                            });
                          },
                        ),
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_all_outlined,
                              color: Colors.orange, size: 20),
                          tooltip: 'Copy Code',
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: response.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Copied to clipboard!')));
                          },
                        ),
                      ],
                    ),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final payload = _appData['payload'] as Map<String, dynamic>? ?? {};
    final displayData = Map<String, dynamic>.from(payload);
    // Display all data, stringifying complex types if needed
    // displayData.removeWhere((key, value) => value == null); // Optional: hide nulls

    if (displayData.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
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
    );
  }

  Widget _buildTimelineChecklist() {
    return Column(
      children: _checklist.keys.map((key) {
        final isChecked = _checklist[key] ?? false;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Line
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked ? successColor : Colors.transparent,
                      border: Border.all(
                          color: isChecked ? successColor : secondaryText),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  Expanded(child: Container(width: 2, color: Colors.white10)),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: InkWell(
                    onTap: () async {
                      final newValue = !isChecked;
                      setState(() {
                        _checklist[key] = newValue; // Optimistic
                      });
                      try {
                        await _appService.updateProcessingStep(
                            applicationId: _appData['_id'],
                            step: key,
                            completed: newValue);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update: $e')));
                          setState(() {
                            _checklist[key] = !newValue; // Revert
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? successColor.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isChecked
                                ? successColor.withValues(alpha: 0.3)
                                : Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(key,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white, fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssignmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152A42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryText.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_ind, size: 40, color: primaryText),
          const SizedBox(height: 16),
          Text(
            'New Application',
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Take ownership of this task to start processing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _assignToSelf,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryText,
                foregroundColor: bgColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Assign to Self',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompletionAction() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _completeTask,
        icon: const Icon(Icons.check_circle_outline),
        label: Text('Mark Complete',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: successColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _requestAction,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label:
                Text('Request Info', style: GoogleFonts.outfit(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _rejectTask,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text('Reject', style: GoogleFonts.outfit(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: errorColor,
              side: const BorderSide(color: errorColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic, color: secondaryText),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need Help?',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Contact Supervisor',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: secondaryText.withValues(alpha: 0.2)),
        image: const DecorationImage(
          image: NetworkImage(
              'https://www.transparenttextures.com/patterns/cubes.png'), // Subtle pattern if possible, or just remove
          opacity: 0.05,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryText.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                color: primaryText, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload Deliverables',
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Drag & drop or tap to browse',
            style: GoogleFonts.outfit(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Upload feature unavailable in demo')));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryText),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child:
                  Text('Browse', style: GoogleFonts.outfit(color: primaryText)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return TextField(
      controller: _commentController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add internal notes...',
        hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5)),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
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
      return Row(
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
      );
    }

    // If sensitive, show shielded view
    return Row(
      children: [
        Row(
          children: [
            Text(widget.label,
                style: GoogleFonts.outfit(color: secondaryText, fontSize: 12)),
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
    );
  }
}
