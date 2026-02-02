import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Mock Data Model ---
class StaffMember {
  final String id;
  final String name;
  final String role;
  final int currentTaskCount;
  final bool isOnline;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.currentTaskCount,
    required this.isOnline,
  });
}

class AssignTaskSheet extends StatefulWidget {
  final String applicationId;

  const AssignTaskSheet({super.key, required this.applicationId});

  @override
  State<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<AssignTaskSheet> {
  // --- Theme Colors ---
  static const sheetColor = Color(0xFF052659);
  // static const primaryText = Color(0xFFC1E8FF); // Unused
  static const secondaryText = Color(0xFF7DA0CA);
  static const highlightGold = Color(0xFFFFD700);
  static const alertRed = Color(0xFFFF6B6B);
  static const selectionColor = Color(0xFF0A3A6B);

  // --- State ---
  String? _selectedStaffId;

  // --- Mock Staff Data ---
  final List<StaffMember> _staffMembers = [
    StaffMember(
      id: 'S001',
      name: 'John Doe',
      role: 'KRA Specialist',
      currentTaskCount: 2,
      isOnline: true,
    ),
    StaffMember(
      id: 'S002',
      name: 'Alice Wambui',
      role: 'eCitizen Expert',
      currentTaskCount: 7, // High workload
      isOnline: true,
    ),
    StaffMember(
      id: 'S003',
      name: 'Peter Kamau',
      role: 'General Staff',
      currentTaskCount: 4,
      isOnline: false,
    ),
    StaffMember(
      id: 'S004',
      name: 'Sarah J.',
      role: 'HELB Specialist',
      currentTaskCount: 1,
      isOnline: true,
    ),
    StaffMember(
      id: 'S005',
      name: 'Mike O.',
      role: 'Intern',
      currentTaskCount: 0,
      isOnline: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: sheetColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          // 1. Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Header
          Text(
            'Assign Application #${widget.applicationId}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a staff member to handle this request.',
            style: GoogleFonts.poppins(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // 3. Staff List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _staffMembers.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final staff = _staffMembers[index];
                final isSelected = _selectedStaffId == staff.id;
                final isHighLoad = staff.currentTaskCount > 5;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStaffId = staff.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectionColor
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: highlightGold, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            staff.name[0],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    staff.role,
                                    style: GoogleFonts.poppins(
                                      color: secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('•',
                                      style: TextStyle(color: Colors.white24)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${staff.currentTaskCount} Tasks',
                                    style: GoogleFonts.poppins(
                                      color:
                                          isHighLoad ? alertRed : secondaryText,
                                      fontSize: 12,
                                      fontWeight: isHighLoad
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Radio/Check
                        if (isSelected)
                          const Icon(Icons.check_circle, color: highlightGold)
                        else
                          Icon(Icons.radio_button_unchecked,
                              color: secondaryText.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // 4. Action Area
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: secondaryText),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedStaffId == null
                      ? null
                      : () {
                          // Return the selected ID
                          Navigator.pop(context, _selectedStaffId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: highlightGold,
                    foregroundColor:
                        const Color(0xFF021024), // Dark Text on Gold
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirm Assignment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
