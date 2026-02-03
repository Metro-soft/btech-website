import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String _title = '';
  String _description = '';
  String _basePrice = '';
  String _category = 'OTHER';

  final List<String> _categories = [
    'All',
    'KRA',
    'HELB',
    'Banking',
    'ETA',
    'KUCCPS',
    'OTHER'
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
        _title = service['title'] ?? service['name'] ?? '';
        _description = service['description'] ?? '';
        _basePrice = service['basePrice']?.toString() ?? '';
        _category = service['category'] ?? 'OTHER';
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
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final data = {
        "title": _title,
        "name": _title, // Maintain legacy name
        "category": _category,
        "description": _description,
        "basePrice": double.tryParse(_basePrice) ?? 0,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AdminTheme.background,
        body: Center(
            child: CircularProgressIndicator(color: AdminTheme.primaryAccent)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
            backgroundColor: AdminTheme.background,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop())),
        body: Center(
            child: Text("Error: $_errorMessage",
                style: const TextStyle(color: AdminTheme.dangerRed))),
      );
    }

    final dropdownCategories = _categories.where((c) => c != 'All').toList();
    if (!dropdownCategories.contains(_category))
      dropdownCategories.add(_category);

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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminTheme.background,
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, size: 20),
            label: const Text("SAVE SERVICE",
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryAccent,
              foregroundColor: AdminTheme.background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          child: _buildTextField(
                            label: "Service Name",
                            initialValue: _title,
                            hint: "e.g. KRA Returns",
                            onSaved: (v) => _title = v!,
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
                                initialValue:
                                    dropdownCategories.contains(_category)
                                        ? _category
                                        : dropdownCategories.first,
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
                            initialValue: _basePrice,
                            hint: "0.00",
                            isNumeric: true,
                            onSaved: (v) => _basePrice = v!,
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Expanded(child: SizedBox()), // Spacer
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: "Description",
                      initialValue: _description,
                      hint: "Describe the service...",
                      maxLines: 4,
                      onSaved: (v) => _description = v!,
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
                    const Text("Dynamic Form Builder",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required String initialValue,
      String? hint,
      bool isNumeric = false,
      int maxLines = 1,
      required Function(String?) onSaved}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.label(label),
        TextFormField(
          initialValue: initialValue,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: AdminFormStyles.inputDecoration(hint: hint),
          validator: (val) => val!.isEmpty ? "Required" : null,
          onSaved: onSaved,
        ),
      ],
    );
  }
}
