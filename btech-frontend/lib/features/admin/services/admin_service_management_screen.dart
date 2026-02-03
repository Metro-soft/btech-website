import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../shared/admin_theme.dart';
import 'data/admin_service_management_service.dart';

class AdminServiceManagementScreen extends StatefulWidget {
  const AdminServiceManagementScreen({super.key});

  @override
  State<AdminServiceManagementScreen> createState() =>
      _AdminServiceManagementScreenState();
}

class _AdminServiceManagementScreenState
    extends State<AdminServiceManagementScreen> {
  final AdminServiceManagementService _service =
      AdminServiceManagementService();

  List<dynamic> _allServices = [];
  List<dynamic> _filteredServices = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  final List<String> _categories = [
    'All',
    'KRA',
    'HELB',
    'Banking',
    'ETA',
    'KUCCPS',
    'OTHER'
  ];
  String _selectedCategory = 'All';

  // Selection
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final services = await _service.getAllServices();
      setState(() {
        _allServices = services;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedCategory == 'All') {
      _filteredServices = List.from(_allServices);
    } else {
      _filteredServices = _allServices
          .where((s) => s['category'] == _selectedCategory)
          .toList();
    }
    _selectedIds.clear();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilter();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.addAll(_filteredServices.map((s) => s['_id'].toString()));
      } else {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _bulkDisable() async {
    await _performBulkAction((id) async {
      final service = _allServices.firstWhere((s) => s['_id'] == id);
      if (service['isActive'] == false) return;
      await _service.updateService(id, {'isActive': false});
    }, "Disabled");
  }

  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Services?",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
            "Are you sure you want to delete ${_selectedIds.length} services? This cannot be undone.",
            style: const TextStyle(color: Colors.white70)),
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
      await _performBulkAction((id) => _service.deleteService(id), "Deleted");
    }
  }

  Future<void> _performBulkAction(
      Future<void> Function(String id) action, String actionName) async {
    if (!mounted) return;
    try {
      final List<String> ids = _selectedIds.toList();
      for (final id in ids) {
        await action(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$actionName ${ids.length} services successfully")));
      _fetchServices();
      _selectedIds.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error performing bulk action: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Sticky Header is handled in the List below, but this is the Page Header)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Services",
                    style: AdminTheme.header.copyWith(fontSize: 28)),
                const SizedBox(height: 4),
                Text("Manage your digital service offerings",
                    style: AdminTheme.body.copyWith(fontSize: 14)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => context.go('/admin/services/create'),
              icon: const Icon(Icons.add_circle_outline,
                  color: AdminTheme.background, size: 20),
              label: const Text("Create Service",
                  style: TextStyle(
                      color: AdminTheme.background,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryAccent,
                foregroundColor: AdminTheme.background,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Filter Bar (Compact)
        Container(
          height: 36, // Reduced height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (c, i) =>
                const SizedBox(width: 8), // Tighter spacing
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return InkWell(
                onTap: () => _onCategorySelected(category),
                borderRadius:
                    BorderRadius.circular(6), // Slightly clearer edge radius
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isSelected
                            ? AdminTheme.primaryAccent
                            : Colors.white12,
                        width: 1),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                        color: isSelected
                            ? AdminTheme.primaryAccent
                            : Colors.white60,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 13 // Smaller font
                        ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Bulk Action Indicator (Subtle)
        if (_selectedIds.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8), // Reduced padding
            decoration: BoxDecoration(
              color: AdminTheme.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AdminTheme.primaryAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AdminTheme.primaryAccent),
                const SizedBox(width: 8),
                Text("${_selectedIds.length} items selected",
                    style: const TextStyle(
                        color: AdminTheme.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _bulkDisable,
                  icon: const Icon(Icons.block,
                      size: 16, color: AdminTheme.warningOrange),
                  label: const Text("Disable",
                      style: TextStyle(
                          color: AdminTheme.warningOrange, fontSize: 13)),
                  style: TextButton.styleFrom(
                      backgroundColor:
                          AdminTheme.warningOrange.withValues(alpha: 0.1)),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _bulkDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AdminTheme.dangerRed),
                  label: const Text("Delete",
                      style:
                          TextStyle(color: AdminTheme.dangerRed, fontSize: 13)),
                  style: TextButton.styleFrom(
                      backgroundColor:
                          AdminTheme.dangerRed.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Main Table Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AdminTheme.primaryAccent))
              : _errorMessage != null
                  ? Center(
                      child: Text("Error: $_errorMessage",
                          style: const TextStyle(color: AdminTheme.dangerRed)))
                  : _filteredServices.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open_outlined,
                                size: 48, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text("No services found in $_selectedCategory",
                                style: const TextStyle(color: Colors.white38)),
                          ],
                        ))
                      : _buildStickyTable(),
        ),
      ],
    );
  }

  // Sticky Header Implementation
  Widget _buildStickyTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Fixed Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05)))),
            child: Row(
              children: [
                _buildHeaderCell(
                    flex: 1,
                    child: SizedBox(
                      width: 20,
                      child: Checkbox(
                        value:
                            _selectedIds.length == _filteredServices.length &&
                                _filteredServices.isNotEmpty,
                        onChanged: (val) => _selectAll(val),
                        activeColor: AdminTheme.primaryAccent,
                        checkColor: AdminTheme.background,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    )),
                _buildHeaderCell(flex: 7, label: "SERVICE IMP"),
                _buildHeaderCell(flex: 3, label: "CATEGORY"),
                _buildHeaderCell(flex: 3, label: "PRICE"),
                _buildHeaderCell(flex: 2, label: "STATUS"),
                _buildHeaderCell(
                    flex: 2,
                    label: "ACTIONS",
                    alignment: Alignment.centerRight),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView.separated(
              itemCount: _filteredServices.length,
              separatorBuilder: (context, index) => Divider(
                  height: 1, color: Colors.white.withValues(alpha: 0.03)),
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return _buildServiceRow(service);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
      {int flex = 1,
      String? label,
      Widget? child,
      Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        child: child ??
            Text(label ?? '',
                style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1)),
      ),
    );
  }

  Widget _buildServiceRow(Map<String, dynamic> service) {
    final id = service['_id'];
    final isSelected = _selectedIds.contains(id);
    final isActive = service['isActive'] == true;

    return InkWell(
      onTap: () => _toggleSelection(id),
      hoverColor: Colors.white.withValues(alpha: 0.02),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: isSelected
            ? AdminTheme.primaryAccent.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(id),
                      activeColor: AdminTheme.primaryAccent,
                      checkColor: AdminTheme.background,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                )),
            Expanded(
                flex: 7,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.grid_view,
                          size: 18, color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Text(service['title'] ?? 'Untitled',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis)),
                  ],
                )),
            Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      service['category'] ?? 'General',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                )),
            Expanded(
                flex: 3,
                child: Text("\$${service['basePrice'] ?? 0}",
                    style: const TextStyle(
                        color: AdminTheme.primaryAccent,
                        fontWeight: FontWeight.bold))),
            Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      activeThumbColor: AdminTheme.primaryAccent,
                      activeTrackColor:
                          AdminTheme.primaryAccent.withValues(alpha: 0.2),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.white10,
                      onChanged: (val) => _toggleStatus(id, val),
                    ),
                  ),
                )),
            Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white54),
                    onPressed: () => context.go('/admin/services/edit/$id'),
                    tooltip: "Edit details",
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(String id, bool newStatus) async {
    try {
      await _service.updateService(id, {'isActive': newStatus});
      _fetchServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    }
  }
}
