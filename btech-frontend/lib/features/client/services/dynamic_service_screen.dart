import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/application_service.dart';

class DynamicServiceScreen extends StatefulWidget {
  final String serviceId;

  const DynamicServiceScreen({super.key, required this.serviceId});

  @override
  State<DynamicServiceScreen> createState() => _DynamicServiceScreenState();
}

class _DynamicServiceScreenState extends State<DynamicServiceScreen> {
  final ApplicationService _api = ApplicationService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  Map<String, dynamic>? _serviceDef;
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _fileData = {}; // Stores base64 strings
  final Map<String, String> _fileNameData = {}; // Stores file names for display

  // Stepper State
  int _currentStep = 0;
  List<_StepData> _steps = [];
  final _singleFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      final data = await _api.getServiceById(widget.serviceId);
      final structure = data['formStructure'] as List<dynamic>? ?? [];

      _initializeFormData(structure);
      _buildSteps(structure);

      setState(() {
        _serviceDef = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _initializeFormData(List<dynamic> structure) {
    for (var field in structure) {
      if (field['type'] != 'file' && field['type'] != 'section') {
        _formData[field['name']] = '';
      }
    }
  }

  void _buildSteps(List<dynamic> structure) {
    _steps.clear();
    List<dynamic> currentFields = [];
    String currentTitle = "Basic Details";
    bool pendingStep = false;

    for (var item in structure) {
      if (item['type'] == 'section') {
        if (currentFields.isNotEmpty || pendingStep) {
          _steps.add(_StepData(
              title: currentTitle,
              fields: List.from(currentFields),
              formKey: GlobalKey<FormState>()));
          currentFields.clear();
        }
        currentTitle = item['label'] ?? 'Section';
        pendingStep = true;
      } else {
        currentFields.add(item);
        pendingStep = true;
      }
    }

    if (currentFields.isNotEmpty || pendingStep) {
      _steps.add(_StepData(
          title: currentTitle,
          fields: List.from(currentFields),
          formKey: GlobalKey<FormState>()));
    }

    if (_steps.isEmpty) {
      _steps.add(_StepData(
          title: "Application", fields: [], formKey: GlobalKey<FormState>()));
    }
  }

  Future<void> _pickFile(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png'],
        withData: true,
      );
      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted)
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Max 5MB')));
          return;
        }

        String base64String = base64Encode(file.bytes!);
        setState(() {
          _fileData[fieldName] =
              'data:application/octet-stream;base64,$base64String';
          _fileNameData[fieldName] = file.name;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  Future<void> _submit() async {
    // Final validation
    if (_steps.isNotEmpty) {
      if (!_steps.last.formKey.currentState!.validate()) return;
      _steps.last.formKey.currentState!.save();
    } else {
      if (!_singleFormKey.currentState!.validate()) return;
      _singleFormKey.currentState!.save();
    }

    setState(() => _isSubmitting = true);

    try {
      // Merge text data and file data
      final payloadDetails = Map<String, dynamic>.from(_formData);

      // Structure specific fields
      final fullPayload = {
        'serviceType': _serviceDef?['title'] ?? 'Dynamic Service',
        'details': payloadDetails,
        'documents': _fileData // Attach files
      };

      final result = await _api.submitApplication(
          type: _serviceDef?['category'] ?? 'OTHER', payload: fullPayload);

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${failure.message}')));
        },
        (data) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Submitted! Redirecting...')));
          // Navigate to checkout or success page
          context.go('/checkout/${data['_id']}');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _nextStep() {
    final currentForm = _steps[_currentStep].formKey.currentState;
    if (currentForm != null && currentForm.validate()) {
      currentForm.save();
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  String get _layoutType => _serviceDef?['layoutType'] ?? 'classic';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF021024),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF021024),
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
            child: Text("Error: $_error",
                style: const TextStyle(color: Colors.red))),
      );
    }

    final title = _serviceDef?['title'] ?? 'Service';

    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left align content
        children: [
          _buildHeaderContent(),
          _buildFormContent(isDesktop: false),
        ],
      ),
    );
  }

  Widget _buildFormContent({required bool isDesktop}) {
    // 1. Stepper Layout (New Styled Card)
    if (_layoutType == 'stepper') {
      return _buildStepperLayout(isDesktop);
    }
    // 2. Wizard Layout (Classic Stepper)
    if (_layoutType == 'wizard') {
      return _buildWizardForm(isDesktop);
    }

    if (_steps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "No required fields configured for this service.",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    if (_layoutType == 'accordion') {
      return _buildAccordionLayout(isDesktop: isDesktop);
    }

    // Classic or Compact
    return Form(
      key: _singleFormKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF052659),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            ..._steps.map((step) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_steps.length > 1) ...[
                    const SizedBox(height: 24),
                    Text(step.title,
                        style: const TextStyle(
                            color: Color(0xFF64FFDA),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                  ],
                  _buildFieldGrid(step.fields,
                      forceFullWidth: _layoutType == 'classic'),
                ],
              );
            }),
            const SizedBox(height: 48),
            _buildSubmitButton(isDesktop),
          ],
        ),
      ),
    );
  }

  // New Styled Stepper (Custom Implementation to avoid Layout Issues)
  Widget _buildStepperLayout(bool isDesktop) {
    if (_steps.isEmpty) return const SizedBox();
    final currentStep = _steps[_currentStep];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF052659),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Horizontal Progress Header
          Row(
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index <= _currentStep;
              final isLast = index == _steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isActive ? const Color(0xFF64FFDA) : Colors.white10,
                      ),
                      child: Center(
                        child: isActive
                            ? const Icon(Icons.check,
                                size: 16, color: Color(0xFF052659))
                            : Text("${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Step Title (Visible if active or previously active, or just number?)
                    // Let's show Title if it fits? Or just for current?
                    // User wanted "Progress line top". classic horizontal stepper style.
                    Expanded(
                      child: Text(
                        entry.value.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white24,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Connector Line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < _currentStep
                              ? const Color(0xFF64FFDA)
                              : Colors.white10,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // 2. Current Step Form Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey(_currentStep),
              child: Form(
                key: currentStep.formKey,
                child:
                    _buildFieldGrid(currentStep.fields, forceFullWidth: false),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 3. Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentStep > 0) ...[
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      side: const BorderSide(color: Color(0xFF64FFDA)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: const Text('Back',
                      style: TextStyle(color: Color(0xFF64FFDA))),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    backgroundColor: const Color(0xFF64FFDA),
                    foregroundColor: const Color(0xFF021024),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(
                        _currentStep == _steps.length - 1
                            ? 'Submit Application'
                            : 'Next Step',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Classic Wizard (Unwrapped)
  Widget _buildWizardForm(bool isDesktop) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF021024), // Match background (no card)
        // Ensure onSurface is white so inactive steps are visible
        colorScheme: const ColorScheme.dark(
            primary: Color(0xFF64FFDA), onSurface: Colors.white),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      child: Stepper(
        physics: const NeverScrollableScrollPhysics(), // Let parent scroll
        type: _layoutType == 'stepper'
            ? StepperType.horizontal
            : StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              mainAxisAlignment: isDesktop
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start, // Right align on desktop
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    flex: isDesktop ? 0 : 1,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          side: const BorderSide(color: Color(0xFF64FFDA))),
                      child: const Text('Back',
                          style: TextStyle(color: Color(0xFF64FFDA))),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: isDesktop ? 0 : 1,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        backgroundColor: const Color(0xFF64FFDA),
                        foregroundColor: const Color(0xFF021024)),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text(
                            _currentStep == _steps.length - 1
                                ? 'Submit Application'
                                : 'Next',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        steps: _steps.map((step) {
          return Step(
            title: Text(step.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            isActive: _currentStep >= _steps.indexOf(step),
            state: _currentStep > _steps.indexOf(step)
                ? StepState.complete
                : StepState.indexed,
            content: Form(
              key: step.formKey,
              child: _buildFieldGrid(step.fields, forceFullWidth: false),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderContent() {
    final description = _serviceDef?['description'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(description,
                style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 24),
        ],
        if (_serviceDef?['requirements'] != null &&
            (_serviceDef?['requirements'] as List).isNotEmpty) ...[
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 600), // Flexible width with cap
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2A4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Requirements",
                    style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...(_serviceDef?['requirements'] as List)
                      .map((req) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(Icons.circle,
                                      size: 6, color: Colors.white70),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildAccordionLayout({required bool isDesktop}) {
    return Form(
      key: _singleFormKey,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF052659),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: _steps.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final _StepData step = entry.value;
                  final bool isLast = index == _steps.length - 1;

                  return Column(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor:
                              Colors.transparent, // Remove default lines
                          colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF64FFDA)), // Icon color
                        ),
                        child: ExpansionTile(
                          title: Text(
                            step.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor:
                              Colors.black12, // Slightly darker when open
                          collapsedBackgroundColor: Colors.transparent,
                          iconColor: const Color(0xFF64FFDA),
                          collapsedIconColor: Colors.white70,
                          childrenPadding: const EdgeInsets.all(20),
                          children: [
                            _buildFieldGrid(step.fields, forceFullWidth: false)
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(height: 1, color: Colors.white10),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 48),
          _buildSubmitButton(isDesktop),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDesktop) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 250,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF021024),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit Application'),
        ),
      ),
    );
  }

  Widget _buildFieldGrid(List<dynamic> fields, {bool forceFullWidth = false}) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      return Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 0, // Handled by padding
        runSpacing: 0,
        children: fields
            .map((f) =>
                _buildDynamicField(f, width, forceFullWidth: forceFullWidth))
            .toList(),
      );
    });
  }

  Widget _buildDynamicField(Map<String, dynamic> field, double parentWidth,
      {bool forceFullWidth = false}) {
    if (field['type'] == 'section') return const SizedBox.shrink();

    final String type = field['type'];
    final String label = field['label'];
    final String name = field['name'];
    final bool required = field['required'] ?? false;
    final List<dynamic> options = field['options'] ?? [];

    // Width calculation
    final double widthFactor = forceFullWidth
        ? 1.0
        : (field['width'] is num)
            ? (field['width'] as num).toDouble()
            : 1.0;
    final double fieldWidth = parentWidth * widthFactor;

    return SizedBox(
        width: fieldWidth,
        child: Padding(
          padding: const EdgeInsets.only(
              bottom: 24, right: 12), // Right padding for spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$label${required ? ' *' : ''}",
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (type == 'text' || type == 'number' || type == 'date')
                TextFormField(
                  initialValue: _formData[name] ?? '',
                  keyboardType: type == 'number'
                      ? TextInputType.number
                      : TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(),
                  onChanged: (val) => _formData[name] = val, // Persist data
                  onSaved: (val) => _formData[name] = val,
                  validator: (val) {
                    if (required && (val == null || val.isEmpty))
                      return "Required";
                    return null;
                  },
                )
              else if (type == 'dropdown')
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(),
                  items: options
                      .map((e) => DropdownMenuItem(
                            value: e.toString(),
                            child: Text(e.toString()),
                          ))
                      .toList(),
                  onChanged: (val) => _formData[name] = val,
                  validator: (val) {
                    if (required && val == null) return "Required";
                    return null;
                  },
                )
              else if (type == 'file')
                InkWell(
                  onTap: () => _pickFile(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF021024), // Maintain contrast here too
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: required && _fileData[name] == null
                              ? Colors.redAccent.withOpacity(0.5)
                              : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: Color(0xFF64FFDA)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Text(
                          _fileNameData[name] ?? "Tap to upload file",
                          style: TextStyle(
                              color: _fileNameData[name] != null
                                  ? Colors.white
                                  : Colors.white38,
                              fontStyle: _fileNameData[name] != null
                                  ? FontStyle.normal
                                  : FontStyle.italic),
                        )),
                      ],
                    ),
                  ),
                )
              else if (type == 'checkbox')
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      const Text("Yes", style: TextStyle(color: Colors.white)),
                  value: _formData[name] == 'true',
                  activeColor: const Color(0xFF64FFDA),
                  onChanged: (val) =>
                      setState(() => _formData[name] = val.toString()),
                ),
            ],
          ),
        ));
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF021024), // Revert to dark
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF64FFDA))),
    );
  }
}

class _StepData {
  final String title;
  final List<dynamic> fields;
  final GlobalKey<FormState> formKey;

  _StepData({required this.title, required this.fields, required this.formKey});
}
