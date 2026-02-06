import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/admin_theme.dart';
import 'data/admin_user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedFilter = 'All';
  final AdminUserService _userService = AdminUserService();
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    setState(() {
      _usersFuture = _userService.getAllUsers(role: _selectedFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("User Management", style: AdminTheme.header),
            Container(
              width: 300,
              decoration: AdminTheme.glassDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white38),
                ),
              ),
            )
          ],
        ),

        const SizedBox(height: 25),

        // 2. Filter Chips & Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Staff'),
                _buildFilterChip('client'),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(),
              icon: const Icon(Icons.add, color: AdminTheme.background),
              label: const Text("Create User",
                  style: TextStyle(
                      color: AdminTheme.background,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            )
          ],
        ),

        const SizedBox(height: 20),

        // 3. THE TABLE HEADER
        _buildTableHeader(),

        const SizedBox(height: 10),

        // 4. THE DATA LIST (Real Data)
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AdminTheme.primaryAccent));
              } else if (snapshot.hasError) {
                return Center(
                    child: Text("Error: ${snapshot.error}",
                        style: const TextStyle(color: AdminTheme.dangerRed)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text("No users found",
                        style: TextStyle(color: Colors.white54)));
              }

              final users = snapshot.data!;
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildUserListRow(users[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    String displayLabel = label == 'client' ? 'Clients' : label;

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ChoiceChip(
        label: Text(displayLabel),
        labelStyle:
            TextStyle(color: isSelected ? AdminTheme.background : Colors.white),
        selected: isSelected,
        selectedColor: AdminTheme.primaryAccent,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.white24)),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedFilter = label;
            });
            _fetchUsers();
          }
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text("USER / ID",
                  style: AdminTheme.subHeader
                      .copyWith(fontSize: 12, color: Colors.white54))),
          Expanded(
              flex: 2,
              child: Text("ROLE",
                  style: AdminTheme.subHeader
                      .copyWith(fontSize: 12, color: Colors.white54))),
          Expanded(
              flex: 2,
              child: Text("PHONE",
                  style: AdminTheme.subHeader
                      .copyWith(fontSize: 12, color: Colors.white54))),
          Expanded(
              flex: 2,
              child: Text("CREATED AT",
                  style: AdminTheme.subHeader
                      .copyWith(fontSize: 12, color: Colors.white54))),
          Expanded(
              flex: 1,
              child: Text("STATUS",
                  style: AdminTheme.subHeader
                      .copyWith(fontSize: 12, color: Colors.white54))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ... (keep existing code until _buildUserListRow)

  Widget _buildUserListRow(dynamic user) {
    // Determine status logic using existing 'isActive' field from DB, default to true
    bool isActive = user['isActive'] ?? true;
    String status = isActive ? "Active" : "Banned";
    Color statusColor =
        isActive ? AdminTheme.successGreen : AdminTheme.dangerRed;

    String name = user['name'] ?? 'Unknown';
    String _rawId = user['_id']?.toString() ?? '...';
    String id =
        _rawId.length >= 6 ? _rawId.substring(_rawId.length - 6) : _rawId;
    String role = user['role'] ?? 'User';
    String phone = user['phone'] ?? 'N/A';
    String createdAt = user['createdAt'] != null
        ? user['createdAt'].toString().substring(0, 10)
        : 'N/A';

    return InkWell(
      onTap: () {
        context.push('/admin/users/details', extra: user);
      },
      child: Container(
        decoration: AdminTheme.glassDecoration.copyWith(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            // Col 1: Name & Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white10,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AdminTheme.primaryAccent, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("#$id",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Col 2: Role
            Expanded(
              flex: 2,
              child: Text(role.toUpperCase(),
                  style: const TextStyle(color: Colors.white70)),
            ),

            // Col 3: Phone
            Expanded(
              flex: 2,
              child: Text(phone, style: const TextStyle(color: Colors.white70)),
            ),

            // Col 4: Created At
            Expanded(
              flex: 2,
              child: Text(createdAt,
                  style: const TextStyle(color: Colors.white38)),
            ),

            // Col 5: Status Badge
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Col 6: Action Menu
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white38),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showUserDialog(user: user);
                  } else if (value == 'delete') {
                    _deleteUser(user['_id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text("Delete", style: TextStyle(color: Colors.red))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        title:
            const Text("Delete User?", style: TextStyle(color: Colors.white)),
        content: const Text(
            "Are you sure you want to delete this user? This action cannot be undone.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: AdminTheme.dangerRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await _userService.deleteUser(id);
        if (!mounted) return;
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final bool isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    String name = user?['name'] ?? '';
    String email = user?['email'] ?? '';
    String phone = user?['phone'] ?? '';
    String role = user?['role'] ?? 'client';
    String password = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AdminTheme.surface,
          title: Text(isEditing ? "Edit User" : "Create User",
              style: AdminTheme.header.copyWith(fontSize: 20)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      onSaved: (val) => name = val!,
                      validator: (val) =>
                          val!.isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: email,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      onSaved: (val) => email = val!,
                      validator: (val) =>
                          val!.isEmpty ? "Email is required" : null,
                    ),
                    const SizedBox(height: 15),
                    if (!isEditing) ...[
                      TextFormField(
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24)),
                        ),
                        onSaved: (val) => password = val!,
                        validator: (val) =>
                            val!.isEmpty ? "Password is required" : null,
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextFormField(
                      initialValue: phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Phone",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      onSaved: (val) => phone = val!,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      dropdownColor: AdminTheme.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Role",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      items: ['client', 'staff', 'admin']
                          .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.toUpperCase(),
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) => role = val!,
                      onSaved: (val) => role = val!,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryAccent),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final data = {
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "role": role,
                  };
                  if (!isEditing) {
                    data["password"] = password;
                  }

                  try {
                    if (isEditing) {
                      await _userService.updateUser(user['_id'], data);
                    } else {
                      await _userService.createUser(data);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _fetchUsers();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(isEditing ? "User updated" : "User created")));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                }
              },
              child: Text(isEditing ? "Save Changes" : "Create User",
                  style: const TextStyle(
                      color: AdminTheme.background,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
