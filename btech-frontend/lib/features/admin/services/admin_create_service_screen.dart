import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // Added for Timer
import '../shared/admin_theme.dart';
import '../shared/admin_form_styles.dart';
import 'data/admin_service_management_service.dart';
import 'widgets/form_builder_widget.dart';

class AdminCreateServiceScreen extends StatefulWidget {
  final String? serviceId; // If null, we are creating

  const AdminCreateServiceScreen({super.key, this.serviceId});

  @override
  State<AdminCreateServiceScreen> createState() =>
      _AdminCreateServiceScreenState();
}

class _AdminCreateServiceScreenState extends State<AdminCreateServiceScreen> {
  final AdminServiceManagementService _service =
      AdminServiceManagementService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isInit = true;
  String? _errorMessage;

  // Form Fields
  String _aiPrompt = '';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  String _category = 'OTHER';
  String _layoutType = 'classic';

  final List<String> _categories = [
    'All',
    'KRA',
    'HELB',
    'Banking',
    'ETA',
    'KUCCPS',
    'OTHER'
  ];

  final List<String> _layouts = [
    'classic',
    'compact',
    'wizard',
    'accordion',
    'stepper'
  ];

  List<Map<String, dynamic>> _formStructure = [];
  List<String> _requirements = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.serviceId != null) {
        _fetchServiceDetails();
      } else {
        // Initialize default empty structure or other defaults
      }
      _isInit = false;
    }
  }

  Future<void> _fetchServiceDetails() async {
    setState(() => _isLoading = true);
    try {
      // We reusing getAllServices for now as we don't have a direct getById in the specific admin service yet,
      // or we can use the main ApplicationService if it's shared.
      // For efficiency, I'll assumme getAllServices is cached or quick enough,
      // OR I should use the method I just added to ApplicationService.
      // Ideally, AdminServiceManagementService should have getServiceById.
      // Let's implement a local lookup from getAllServices since we likely just came from there
      // BUT for correctness we should fetch fresh.
      // I'll assume we can use the backend endpoint directly if I had the method.
      // For now, I will use the method I added to ApplicationService in the previous step
      // OR add one to AdminServiceManagementService. `getServiceById` exists in `ApplicationService`.
      // I will duplicate logic or use ApplicationService. Let's use clean approach:
      // Since I don't have access to ApplicationService instance here easily without importing core,
      // I will quickly add getServiceById to AdminServiceManagementService or use the one I know works.

      // Temporary: Use getAllServices and filter (Not efficient but works for small lists)
      // Better: Add getById to AdminServiceManagementService.
      final services = await _service.getAllServices();
      final service = services.firstWhere((s) => s['_id'] == widget.serviceId,
          orElse: () => {});

      if (service.isNotEmpty) {
        _titleController.text = service['title'] ?? service['name'] ?? '';
        _descriptionController.text = service['description'] ?? '';
        _basePriceController.text = service['basePrice']?.toString() ?? '';
        _category = service['category'] ?? 'OTHER';
        _layoutType = service['layoutType'] ?? 'classic';
        if (service['formStructure'] != null) {
          _formStructure =
              List<Map<String, dynamic>>.from(service['formStructure']);
        }
        if (service['requirements'] != null) {
          _requirements = List<String>.from(service['requirements']);
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final data = {
        "title": _titleController.text,
        "name": _titleController.text, // Maintain legacy name
        "category": _category,
        "layoutType": _layoutType,
        "description": _descriptionController.text,
        "basePrice": double.tryParse(_basePriceController.text) ?? 0,
        "formStructure": _formStructure,
        "requirements": _requirements,
      };

      if (widget.serviceId != null) {
        await _service.updateService(widget.serviceId!, data);
      } else {
        await _service.createService(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.serviceId != null
                ? "Service Updated"
                : "Service Created")));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // Loading State
  String _loadingMessage = "Analyzing Request...";
  Timer? _loadingTimer;
  final List<String> _loadingMessages = [
    "Analyzing Service Name...",
    "Determining Best Category...",
    "Designing Form Structure...",
    "Drafting Requirements...",
    "Calculating Base Price...",
    "Polishing Details...",
    "Finalizing Service..."
  ];

  @override
  @override
  void dispose() {
    _loadingTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  Future<void> _generateAiContent() async {
    // Start AI Generation
    if (_aiPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe the service first")),
      );
      return;
    }

    // ORPHANED CODE START
    /*
    final userPrompt = await showDialog<String>(
      context: context,
      builder: (context) {
        String prompt = "Create a service for $_title";
        if (_title.isEmpty) prompt = "";

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("✨ Magic Auto-Fill",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Describe the service you want to build. The AI will generate the category, layout, price, and form fields.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: prompt,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: AdminFormStyles.inputDecoration(
                    hint: "e.g. Visa application for UK with high price..."),
                onChanged: (val) => prompt = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () => context.pop(prompt),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text("Generate"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC69C6D),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        );
      },
    );
    */

    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    // Start Message Cycle
    int messageIndex = 0;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        messageIndex = (messageIndex + 1) % _loadingMessages.length;
        _loadingMessage = _loadingMessages[messageIndex];
      });
    });

    try {
      // Pass empty category if we want AI to decide, or pass current if we want to bias it?
      // The backend prompt now ignores the passed category mostly, but let's send it anyway.
      final data = await _service.generateFullService(
          title: _titleController.text, // Use updated title if any
          category: _category,
          userPrompt: _aiPrompt);

      _loadingTimer?.cancel();

      setState(() {
        if (data['title'] != null) {
          _titleController.text = data['title'];
        }

        if (data['category'] != null) {
          // Ensure it's a valid category
          if (_categories.contains(data['category'])) {
            _category = data['category'];
          }
        }

        if (data['layoutType'] != null) {
          if (_layouts.contains(data['layoutType'])) {
            _layoutType = data['layoutType'];
          }
        }

        if (data['description'] != null) {
          _descriptionController.text = data['description'];
        }

        if (data['basePrice'] != null) {
          _basePriceController.text = data['basePrice'].toString();
        }

        if (data['requirements'] != null) {
          _requirements = List<String>.from(data['requirements']);
        }

        if (data['formStructure'] != null) {
          _formStructure =
              List<Map<String, dynamic>>.from(data['formStructure']);
        }
      });

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✨ Service magically generated!"),
          backgroundColor: Color(0xFFC69C6D),
        ));
      }
    } catch (e) {
      _loadingTimer?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine content to show
    Widget content = _buildFormContent();

    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        backgroundColor: AdminTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.serviceId != null ? "Edit Service" : "New Service",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: const [],
      ),
      bottomNavigationBar: !_isLoading
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.background,
                border: Border(
                    top:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text("SAVE SERVICE",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryAccent,
                    foregroundColor: AdminTheme.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          content,
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Color(0xFFC69C6D),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        color: Color(0xFFC69C6D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Powered by Gemini AI",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    if (_errorMessage != null) {
      return Center(
          child: Text("Error: $_errorMessage",
              style: const TextStyle(color: AdminTheme.dangerRed)));
    }

    final dropdownCategories = _categories.where((c) => c != 'All').toList();
    if (!dropdownCategories.contains(_category)) {
      dropdownCategories.add(_category);
    }

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Assistant Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFC69C6D).withValues(alpha: 0.15),
                      const Color(0xFF1E1E2C)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFC69C6D).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Color(0xFFC69C6D), size: 20),
                        SizedBox(width: 8),
                        Text("AI Assistant",
                            style: TextStyle(
                                color: Color(0xFFC69C6D),
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Describe the service you want to create (e.g. \"KRA Tax Returns filing with upload fields\"). The AI will generate everything for you.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _aiPrompt,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: AdminFormStyles.inputDecoration(
                          hint: "Describe your service here..."),
                      onChanged: (val) => _aiPrompt = val,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _generateAiContent,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text("Magic Auto-Fill"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC69C6D),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Basic Details Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Basic Information",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: "Service Name",
                                controller: _titleController,
                                hint: "e.g. KRA Returns",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminFormStyles.label("Category"),
                              DropdownButtonFormField<String>(
                                key: ValueKey(_category),
                                initialValue: dropdownCategories
                                        .contains(_category)
                                    ? _category
                                    : dropdownCategories
                                        .first, // Fixed initialValue to value
                                dropdownColor: const Color(0xFF2A2A3E),
                                style: const TextStyle(color: Colors.white),
                                decoration: AdminFormStyles.inputDecoration(),
                                items: dropdownCategories
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _category = val!),
                              ),
                              const SizedBox(height: 16),
                              AdminFormStyles.label("Layout Mold"),
                              DropdownButtonFormField<String>(
                                key: ValueKey(_layoutType),
                                initialValue:
                                    _layoutType, // Fixed initialValue to value
                                dropdownColor: const Color(0xFF2A2A3E),
                                style: const TextStyle(color: Colors.white),
                                decoration: AdminFormStyles.inputDecoration(),
                                items: _layouts
                                    .map((l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l == 'wizard'
                                            ? 'Progress Wizard'
                                            : l == 'stepper'
                                                ? 'Stepper'
                                                : l == 'accordion'
                                                    ? 'Accordion View'
                                                    : l == 'compact'
                                                        ? 'Modern Compact'
                                                        : 'Classic Vertical')))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _layoutType = val!),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: "Base Price",
                            controller: _basePriceController,
                            hint: "0.00",
                            isNumeric: true,
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Expanded(child: SizedBox()), // Spacer
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: "Description",
                      controller: _descriptionController,
                      hint: "Describe the service...",
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Requirements Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Requirements",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _requirements.add("");
                            });
                          },
                          icon: const Icon(Icons.add,
                              size: 18, color: AdminTheme.primaryAccent),
                          label: const Text("Add Requirement",
                              style:
                                  TextStyle(color: AdminTheme.primaryAccent)),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AdminTheme.primaryAccent.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_requirements.isEmpty)
                      const Text(
                          "No requirements listed. Add items the client needs to provide.",
                          style: TextStyle(color: Colors.white38)),
                    ..._requirements.asMap().entries.map((entry) {
                      final index = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 8, color: Colors.white24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.value,
                                style: const TextStyle(color: Colors.white),
                                decoration: AdminFormStyles.inputDecoration(
                                    hint: "e.g. ID Scan"),
                                onChanged: (val) {
                                  _requirements[index] = val;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white24, size: 20),
                              onPressed: () {
                                setState(() {
                                  _requirements.removeAt(index);
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form Builder Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Dynamic Form Builder",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        "Define the fields the client must fill out to apply for this service.",
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 24),
                    FormBuilderWidget(
                      initialFields: _formStructure,
                      onFieldsChanged: (fields) {
                        _formStructure = fields;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        ));
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      String? hint,
      bool isNumeric = false,
      int maxLines = 1,
      Function(String?)? onSaved,
      Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.label(label),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: AdminFormStyles.inputDecoration(hint: hint),
          validator: (val) => val!.isEmpty ? "Required" : null,
          onSaved: onSaved,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
