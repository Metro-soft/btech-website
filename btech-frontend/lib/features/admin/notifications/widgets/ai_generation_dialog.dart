import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/admin_theme.dart';

class AiGenerationDialog extends StatefulWidget {
  const AiGenerationDialog({super.key});

  @override
  State<AiGenerationDialog> createState() => _AiGenerationDialogState();
}

class _AiGenerationDialogState extends State<AiGenerationDialog> {
  final TextEditingController _goalController = TextEditingController();
  String _selectedTone = 'PROFESSIONAL'; // PROFESSIONAL, URGENT, FRIENDLY

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: AdminTheme.glassDecoration.copyWith(
          color: const Color(0xFF0F2035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AdminTheme.primaryAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AdminTheme.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  "Generate with AI",
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Goal Input
            Text(
              "What is the goal of this notification?",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'e.g. Notify client about late payment',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: AdminTheme.primaryAccent),
                    borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 16),

            // Tone Selector
            Text(
              "Select Tone",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildToneChip('Professional', 'PROFESSIONAL'),
                const SizedBox(width: 8),
                _buildToneChip('Urgent', 'URGENT'),
                const SizedBox(width: 8),
                _buildToneChip('Friendly', 'FRIENDLY'),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel",
                      style: GoogleFonts.outfit(color: Colors.white54)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_goalController.text.isEmpty) return;
                    Navigator.pop(context, {
                      'goal': _goalController.text,
                      'tone': _selectedTone,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text("Generate"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneChip(String label, String value) {
    final isSelected = _selectedTone == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedTone = value),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: AdminTheme.primaryAccent.withValues(alpha: 0.2),
      checkmarkColor: AdminTheme.primaryAccent,
      labelStyle: GoogleFonts.outfit(
          color: isSelected ? AdminTheme.primaryAccent : Colors.white70),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AdminTheme.primaryAccent : Colors.transparent,
        ),
      ),
    );
  }
}
