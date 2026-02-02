import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/application_service.dart';

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

  @override
  void initState() {
    super.initState();
    _appData = widget.application;
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
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final status = _appData['status'] ?? 'PENDING';
    final type = _appData['type'] ?? 'Service';
    final ticket = _appData['ticketNumber'] ?? '---';
    final date = _appData['createdAt'] != null
        ? DateFormat('MMMM d, yyyy')
            .format(DateTime.parse(_appData['createdAt']))
        : '---';

    final clientAction = _appData['clientAction'] ?? {};
    final isActionRequired = clientAction['required'] == true;

    // Assigned Staff logic

    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Application #$ticket',
            style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _getStatusColor(status).withValues(alpha: 0.5),
                          width: 2),
                    ),
                    child: Icon(_getStatusIcon(status),
                        size: 40, color: _getStatusColor(status)),
                  ),
                  const SizedBox(height: 16),
                  Text(type,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Text(status,
                      style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ACTION REQUIRED CARD
            if (isActionRequired) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F), // Distinct Blue info card
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 10)
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notification_important,
                            color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Action Required',
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(clientAction['message'] ?? 'Please provide input',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _responseController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter code / response here...',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Color(0xFF021024),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitResponse,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Submit Response'),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Timeline Section
            const Text('TRACKING TIMELINE',
                style: TextStyle(
                    color: Colors.white54, fontSize: 14, letterSpacing: 1.2)),
            const SizedBox(height: 24),

            _buildTimelineStep(
              title: 'Application Submitted',
              subtitle: 'completed on $date',
              isActive: true,
              isFirst: true,
              isLast: false,
            ),

            // Interaction Log Logic
            if (clientAction['response'] != null && !isActionRequired)
              _buildTimelineStep(
                  title: 'Input Provided',
                  subtitle: 'You submitted: ${clientAction['response']}',
                  isActive: true,
                  isFirst: false,
                  isLast: false),

            _buildTimelineStep(
              title: 'Processing at HQ',
              subtitle: isActionRequired
                  ? 'Paused: Waiting for your input'
                  : 'Review & Verification in progress',
              isActive: ['ASSIGNED', 'COMPLETED', 'REJECTED', 'IN_PROGRESS']
                  .contains(status),
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

            // Download Button
            if (status == 'COMPLETED') ...[
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download Documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
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
        (isActive ? Colors.green : Colors.grey.withValues(alpha: 0.3));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                      child: Container(
                          width: 2,
                          color: isActive
                              ? Colors.green
                              : Colors.grey.withValues(alpha: 0.2))),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                      child: Container(
                          width: 2,
                          color: isActive
                              ? Colors.green
                              : Colors.grey.withValues(alpha: 0.2))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isActive ? Colors.white : Colors.white24,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
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
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'ASSIGNED':
        return Icons.engineering;
      case 'IN_PROGRESS':
        return Icons.engineering;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
