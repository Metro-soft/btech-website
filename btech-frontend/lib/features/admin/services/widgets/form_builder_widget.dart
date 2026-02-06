import 'package:flutter/material.dart';
import '../../shared/admin_theme.dart';

class FormBuilderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> initialFields;
  final Function(List<Map<String, dynamic>>) onFieldsChanged;

  const FormBuilderWidget({
    super.key,
    required this.initialFields,
    required this.onFieldsChanged,
  });

  @override
  State<FormBuilderWidget> createState() => _FormBuilderWidgetState();
}

class _FormBuilderWidgetState extends State<FormBuilderWidget> {
  late List<Map<String, dynamic>> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.initialFields);
  }

  void _addField() {
    setState(() {
      _fields.add({
        'type': 'text',
        'label': 'New Field',
        'name': 'field_${DateTime.now().millisecondsSinceEpoch}',
        'required': false,
        'options': <String>[],
      });
      widget.onFieldsChanged(_fields);
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
      widget.onFieldsChanged(_fields);
    });
  }

  void _updateField(int index, String key, dynamic value) {
    setState(() {
      final field = Map<String, dynamic>.from(_fields[index]);
      field[key] = value;

      // Auto-generate name from label if name hasn't been manually edited (simple heuristic)
      if (key == 'label') {
        final String label = value as String;
        field['name'] =
            label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      }

      _fields[index] = field;
      widget.onFieldsChanged(_fields);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Form Fields",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            TextButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add_circle,
                  size: 18, color: AdminTheme.primaryAccent),
              label: const Text("Question",
                  style: TextStyle(color: AdminTheme.primaryAccent)),
              style: TextButton.styleFrom(
                backgroundColor:
                    AdminTheme.primaryAccent.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _addSection,
              icon:
                  const Icon(Icons.view_agenda, size: 18, color: Colors.white),
              label:
                  const Text("Section", style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_fields.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text(
                "No fields defined. Add a Section or Question to start.",
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _fields.removeAt(oldIndex);
                _fields.insert(newIndex, item);
                widget.onFieldsChanged(_fields);
              });
            },
            itemBuilder: (context, index) {
              final field = _fields[index];
              if (field['type'] == 'section') {
                return _buildSectionCard(index, field);
              }
              return _buildFieldCard(index, field);
            },
          ),
      ],
    );
  }

  void _addSection() {
    setState(() {
      _fields.add({
        'type': 'section',
        'label': 'New Section',
        'name': 'section_${DateTime.now().millisecondsSinceEpoch}',
      });
      widget.onFieldsChanged(_fields);
    });
  }

  Widget _buildSectionCard(int index, Map<String, dynamic> field) {
    return Container(
      key: ValueKey(field['name'] ?? index),
      margin: const EdgeInsets.only(bottom: 12, top: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AdminTheme.primaryAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AdminTheme.primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.white24, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.view_agenda,
              color: AdminTheme.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: field['label'],
              style: const TextStyle(
                  color: AdminTheme.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Section Title",
                hintStyle: TextStyle(color: Colors.white24),
              ),
              onChanged: (val) => _updateField(index, 'label', val),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white38, size: 20),
            onPressed: () => _removeField(index),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(int index, Map<String, dynamic> field) {
    return Container(
      key: ValueKey(field['name'] ?? index),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.white24, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  field['label'] ?? 'Untitled Field',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AdminTheme.dangerRed, size: 20),
                onPressed: () => _removeField(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  label: "Label",
                  value: field['label'] ?? '',
                  onChanged: (val) => _updateField(index, 'label', val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  label: "Type",
                  value: field['type'] ?? 'text',
                  items: [
                    'text',
                    'number',
                    'date',
                    'file',
                    'dropdown',
                    'checkbox'
                  ],
                  onChanged: (val) => _updateField(index, 'type', val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  label: "Width",
                  value: (field['width'] ?? 1.0).toString(),
                  items: ['1.0', '0.5', '0.33', '0.25'],
                  itemLabels: {
                    '1.0': 'Full',
                    '0.5': '1/2',
                    '0.33': '1/3',
                    '0.25': '1/4'
                  },
                  onChanged: (val) => _updateField(
                      index, 'width', double.tryParse(val!) ?? 1.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Required",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  value: field['required'] == true,
                  activeThumbColor: AdminTheme.primaryAccent,
                  onChanged: (val) => _updateField(index, 'required', val),
                ),
              ),
            ],
          ),
          if (field['type'] == 'dropdown') ...[
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            const Text("Options",
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ...((field['options'] as List<dynamic>?) ?? [])
                      .asMap()
                      .entries
                      .map((entry) {
                    final optIndex = entry.key;
                    final optValue = entry.value.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: optValue,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide.none),
                              ),
                              onChanged: (val) {
                                final options =
                                    List<String>.from(field['options'] ?? []);
                                options[optIndex] = val;
                                _updateField(index, 'options', options);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white24, size: 16),
                            onPressed: () {
                              final options =
                                  List<String>.from(field['options'] ?? []);
                              options.removeAt(optIndex);
                              _updateField(index, 'options', options);
                            },
                          )
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      final options = List<String>.from(field['options'] ?? []);
                      options.add("New Option");
                      _updateField(index, 'options', options);
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text("Add Option",
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminTheme.primaryAccent,
                    ),
                  )
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required String value,
      required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.black26,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown(
      {required String label,
      required String value,
      required List<String> items,
      Map<String, String>? itemLabels,
      required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: const Color(0xFF2A2A3E),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.black26,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none),
          ),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(itemLabels?[e] ?? e,
                      overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
