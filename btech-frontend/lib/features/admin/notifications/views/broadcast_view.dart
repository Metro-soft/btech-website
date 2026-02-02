import 'package:flutter/material.dart';
import '../../shared/admin_theme.dart';
import '../services/template_service.dart';

class BroadcastView extends StatefulWidget {
  const BroadcastView({super.key});

  @override
  State<BroadcastView> createState() => _BroadcastViewState();
}

class _BroadcastViewState extends State<BroadcastView> {
  final TemplateService _templateService = TemplateService();

  // Form State
  String? _selectedAudience; // Changed to nullable and initialized to null
  Map<String, dynamic>? _selectedTemplate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoadingTemplates = true;
  bool _isSending = false;
  List<dynamic> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final data = await _templateService.getTemplates();
      if (mounted) {
        setState(() {
          _templates = data;
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTemplates = false);
    }
  }

  void _onTemplateSelected(String? templateId) {
    setState(() {
      if (templateId != null) {
        final template = _templates.firstWhere((t) => t['_id'] == templateId);
        _selectedTemplate = template;
        _titleController.text = template['title'];
        _messageController.text = template['body'];
      } else {
        _selectedTemplate = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Compose Form
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AdminTheme.glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Compose Broadcast", style: AdminTheme.header),
                const SizedBox(height: 20),

                // Audience Selector
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Target Audience",
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAudience,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white),
                      hint: const Text("Select Audience",
                          style: TextStyle(color: Colors.white24)),
                      items: [
                        {'label': 'All Users', 'value': 'ALL_USERS'},
                        {'label': 'All Clients', 'value': 'CLIENTS'},
                        {'label': 'All Staff', 'value': 'STAFF'},
                        {'label': 'Active Users', 'value': 'ACTIVE'},
                      ]
                          .map((item) => DropdownMenuItem(
                              value: item['value'],
                              child: Text(item['label']!)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAudience = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Template Selector
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Use Template",
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTemplate?['_id'],
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white),
                      hint: Text(
                        _isLoadingTemplates
                            ? "Loading templates..."
                            : "Select a Template (Optional)",
                        style: const TextStyle(color: Colors.white24),
                      ),
                      icon: _isLoadingTemplates
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white24))
                          : const Icon(Icons.arrow_drop_down,
                              color: Colors.white70),
                      items: _templates
                          .map((t) => DropdownMenuItem(
                              value: t['_id'] as String,
                              child: Text(t['title'])))
                          .toList(),
                      onChanged:
                          _isLoadingTemplates ? null : _onTemplateSelected,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Message Body
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                      labelText: "Subject / Title",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Message",
                      alignLabelWithHint: true,
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      helperText: "Supports {{name}} placeholder",
                      helperStyle: TextStyle(color: Colors.white24)),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: _isSending
                            ? null
                            : () async {
                                if (_titleController.text.isEmpty ||
                                    _messageController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a title and message')));
                                  return;
                                }

                                setState(() => _isSending = true);

                                try {
                                  final payload = {
                                    'audience': _selectedAudience,
                                    'title': _titleController.text,
                                    'message': _messageController.text,
                                    'templateId': _selectedTemplate?['_id'],
                                    'type':
                                        'SYSTEM' // Default type for broadcasts
                                  };

                                  await _templateService.sendBroadcast(payload);

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Broadcast Sent Successfully! 🚀'),
                                          backgroundColor: Colors.green));
                                  // Reset form
                                  _titleController.clear();
                                  _messageController.clear();
                                  setState(() => _selectedTemplate = null);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red));
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSending = false);
                                  }
                                }
                              },
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label:
                            Text(_isSending ? "Sending..." : "Send Broadcast"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        // RIGHT: Preview / History (Placeholder)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AdminTheme.glassDecoration
                    .copyWith(color: Colors.white.withValues(alpha: 0.02)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Preview", style: AdminTheme.body),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AdminTheme.primaryAccent,
                                  child: Icon(Icons.notifications,
                                      size: 12, color: Colors.white)),
                              SizedBox(width: 8),
                              Text("BTECH App",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Spacer(),
                              Text("now",
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder(
                              valueListenable: _titleController,
                              builder: (context, value, _) {
                                return Text(
                                    value.text.isEmpty
                                        ? "New Message"
                                        : value.text,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold));
                              }),
                          const SizedBox(height: 4),
                          ValueListenableBuilder(
                              valueListenable: _messageController,
                              builder: (context, value, _) {
                                return Text(
                                    value.text.isEmpty
                                        ? "Your message here..."
                                        : value.text,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12));
                              }),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
