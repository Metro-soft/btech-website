import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../shared/admin_theme.dart';
import '../dashboard/admin_layout.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine data for display
    final String name = widget.user['name'] ?? 'Unknown User';
    final String id = widget.user['_id']?.toString().substring(0, 6) ?? '...';
    final String role = widget.user['role']?.toString().toUpperCase() ?? 'USER';
    final bool isActive = widget.user['isActive'] ?? true;
    final String email = widget.user['email'] ?? 'N/A';
    final String phone = widget.user['phone'] ?? 'N/A';
    final String createdAt = widget.user['createdAt'] != null
        ? widget.user['createdAt'].toString().substring(0, 10)
        : 'N/A';

    return AdminLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BACK BUTTON & BREADCRUMBS
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => context.pop(),
              ),
              const Text("Users / ", style: TextStyle(color: Colors.white38)),
              Text("$id - $name",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 20),

          // 2. HEADER CARD (The MetroNet "Identity" Section)
          _buildHeaderCard(name, id, role, isActive),

          const SizedBox(height: 25),

          // 3. TABS (Glassmorphic Style)
          Container(
            height: 45,
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white12))),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AdminTheme.primaryAccent,
              indicatorWeight: 3,
              labelColor: AdminTheme.primaryAccent,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "General Information"),
                Tab(text: "Applications"),
                Tab(text: "Payments"),
                Tab(text: "Notifications"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. TAB CONTENT AREA
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralInfoTab(name, id, email, phone, role, createdAt),
                _buildPlaceholderTab("Applications List"),
                _buildPlaceholderTab("Transaction History"),
                _buildPlaceholderTab("System Notifications"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderCard(String name, String id, String role, bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AdminTheme.glassDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white10,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 24, color: AdminTheme.primaryAccent)),
          ),
          const SizedBox(width: 20),

          // Basic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AdminTheme.header.copyWith(fontSize: 24)),
                    const SizedBox(width: 15),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: isActive
                              ? AdminTheme.successGreen.withValues(alpha: 0.2)
                              : AdminTheme.dangerRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isActive
                                  ? AdminTheme.successGreen
                                  : AdminTheme.dangerRed)),
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                              size: 8,
                              color: isActive
                                  ? AdminTheme.successGreen
                                  : AdminTheme.dangerRed),
                          const SizedBox(width: 6),
                          Text(isActive ? "Active" : "Banned",
                              style: TextStyle(
                                  color: isActive
                                      ? AdminTheme.successGreen
                                      : AdminTheme.dangerRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text("$role Account • ID #$id", style: AdminTheme.body),
              ],
            ),
          ),

          // Header Action Buttons
          Row(
            children: [
              _buildHeaderActionButton(
                  "Reset Password", Icons.lock_reset_outlined),
              const SizedBox(width: 10),
              if (isActive)
                _buildHeaderActionButton("Suspend", Icons.block_outlined,
                    isDanger: true),
              const SizedBox(width: 10),

              // The Main "Actions" Dropdown Button
              PopupMenuButton<String>(
                onSelected: (value) {
                  // TODO: Implement actions
                },
                itemBuilder: (BuildContext context) {
                  return {'Edit Profile', 'Send Email', 'Delete User'}
                      .map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      const Text("Actions",
                          style: TextStyle(
                              color: AdminTheme.background,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_drop_down, color: AdminTheme.background)
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton(String label, IconData icon,
      {bool isDanger = false}) {
    Color color = isDanger ? AdminTheme.dangerRed : Colors.white;
    return InkWell(
      onTap: () {
        // TODO: Implement action
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: GENERAL INFORMATION ---
  Widget _buildGeneralInfoTab(String name, String id, String email,
      String phone, String role, String createdAt) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(24),
        decoration: AdminTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Account Details", style: AdminTheme.subHeader),
            const SizedBox(height: 5),
            Container(
                width: 40,
                height: 3,
                color: AdminTheme.primaryAccent), // Underline accent
            const SizedBox(height: 30),

            // Grid Layout for info fields
            LayoutBuilder(builder: (context, constraints) {
              // Responsive grid: 3 columns on wide screens, 2 on smaller
              int crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                childAspectRatio: 3.5, // Flatten the boxes
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoField("FULL NAME", name),
                  _buildInfoField("USER ID", id),
                  _buildInfoField("EMAIL ADDRESS", email),
                  _buildInfoField("PHONE NUMBER", phone),
                  _buildInfoField("JOINED DATE", createdAt),
                  _buildInfoField("ACCOUNT TYPE", "$role (Standard)"),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Copy Button
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.white24),
            onPressed: () {
              // TODO: Implement copy
            },
            tooltip: 'Copy $label',
          )
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: AdminTheme.glassDecoration,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 50, color: Colors.white24),
          const SizedBox(height: 20),
          Text("Module: $title", style: AdminTheme.subHeader),
          Text("Coming soon...", style: AdminTheme.body),
        ],
      ),
    );
  }
}
