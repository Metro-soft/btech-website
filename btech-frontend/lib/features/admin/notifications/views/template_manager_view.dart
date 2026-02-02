import 'package:flutter/material.dart';
import '../../shared/admin_theme.dart';
import '../services/template_service.dart';
import '../widgets/ai_generation_dialog.dart';

class TemplateManagerView extends StatefulWidget {
  const TemplateManagerView({super.key});

  @override
  State<TemplateManagerView> createState() => _TemplateManagerViewState();
}

class _TemplateManagerViewState extends State<TemplateManagerView> {
  final TemplateService _service = TemplateService();
  List<dynamic> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final data = await _service.getTemplates();
      if (mounted) {
        setState(() {
          _templates = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showEditor([Map<String, dynamic>? template]) {
    final isEditing = template != null;
    final titleController = TextEditingController(text: template?['title']);
    final bodyController = TextEditingController(text: template?['body']);
    String category = template?['category'] ?? 'GENERAL';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(isEditing ? "Edit Template" : "New Template",
            style: AdminTheme.header),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Title (Internal Name)",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await showDialog<Map<String, String>>(
                      context: context,
                      builder: (c) => const AiGenerationDialog(),
                    );

                    if (result != null && context.mounted) {
                      // Show loading or something? For now just call it
                      try {
                        final aiContent = await _service.generateAiContent(
                            goal: result['goal']!, tone: result['tone']!);

                        titleController.text = aiContent['title'];
                        bodyController.text = aiContent['body'];
                        // Hack to refresh UI if needed, but controllers are bound
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('AI Error: $e')));
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_awesome,
                      color: AdminTheme.primaryAccent, size: 16),
                  label: const Text("Auto-Generate with AI",
                      style: TextStyle(color: AdminTheme.primaryAccent)),
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: const Color(0xFF1E1E2C),
                style: const TextStyle(color: Colors.white),
                items: ['GENERAL', 'FINANCE', 'SYSTEM', 'MARKETING', 'URGENT']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(
                    labelText: "Category",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: bodyController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Message Body",
                    hintText: "Use {{name}} for dynamic values...",
                    hintStyle: TextStyle(color: Colors.white24),
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryAccent),
            onPressed: () async {
              try {
                final data = {
                  'title': titleController.text,
                  'category': category,
                  'body': bodyController.text,
                };

                if (isEditing) {
                  await _service.updateTemplate(template['_id'], data);
                } else {
                  await _service.createTemplate(data);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadTemplates();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isEditing ? "Save Changes" : "Create Template"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Message Templates", style: AdminTheme.header),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showEditor(),
              icon: const Icon(Icons.add),
              label: const Text("New Template"),
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _templates.isEmpty
                  ? Center(
                      child: Text("No templates found", style: AdminTheme.body))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final t = _templates[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AdminTheme.glassDecoration.copyWith(
                              color: Colors.red.withValues(alpha: 0.1)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(t['category'],
                                        style: const TextStyle(fontSize: 10)),
                                    backgroundColor: AdminTheme.primaryAccent
                                        .withValues(alpha: 0.2),
                                    labelStyle: const TextStyle(
                                        color: AdminTheme.primaryAccent),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.white30),
                                    onPressed: () async {
                                      await _service.deleteTemplate(t['_id']);
                                      _loadTemplates();
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(t['title'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 5),
                              Expanded(
                                child: Text(t['body'],
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.fade),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _showEditor(t),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text("Edit"),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.white60),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
        )
      ],
    );
  }
}
