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
  late Future<List<dynamic>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _refreshServices();
  }

  void _refreshServices() {
    setState(() {
      _servicesFuture = _service.getAllServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Service Management", style: AdminTheme.header),
            ElevatedButton.icon(
              onPressed: () => _showServiceDialog(),
              icon: const Icon(Icons.add, color: AdminTheme.background),
              label: const Text("Add New Service",
                  style: TextStyle(
                      color: AdminTheme.background,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Services Grid
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _servicesFuture,
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
                    child: Text("No services found.",
                        style: TextStyle(color: Colors.white54)));
              }

              final services = snapshot.data!;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _buildServiceCard(service);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(dynamic service) {
    return Container(
      decoration: AdminTheme.glassDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service['name'] ?? 'Untitled',
                  style: AdminTheme.subHeader.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showServiceDialog(service: service);
                  } else if (value == 'delete') {
                    _deleteService(service['_id']);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              service['description'] ?? 'No description',
              style: AdminTheme.body.copyWith(fontSize: 13),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: AdminTheme.primaryAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              "Base Price: \$${service['basePrice'] ?? 0}",
              style: const TextStyle(
                  color: AdminTheme.primaryAccent, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _deleteService(String id) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        title: const Text("Delete Service?",
            style: TextStyle(color: Colors.white)),
        content: const Text(
            "Are you sure you want to remove this service? This cannot be undone.",
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
        await _service.deleteService(id);
        if (!mounted) return;
        _refreshServices();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Service deleted successfully")));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  // Dialog for Create and Edit
  void _showServiceDialog({Map<String, dynamic>? service}) {
    final bool isEditing = service != null;
    final formKey = GlobalKey<FormState>();
    String name = service?['name'] ?? '';
    String description = service?['description'] ?? '';
    String basePrice = service?['basePrice']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AdminTheme.surface,
          title: Text(isEditing ? "Edit Service" : "Add New Service",
              style: AdminTheme.header.copyWith(fontSize: 20)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Service Name",
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
                    initialValue: description,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                    ),
                    maxLines: 3,
                    onSaved: (val) => description = val!,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    initialValue: basePrice,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Base Price",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                    ),
                    onSaved: (val) => basePrice = val!,
                    validator: (val) =>
                        val!.isEmpty ? "Price is required" : null,
                  ),
                ],
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
                    "description": description,
                    "basePrice": double.tryParse(basePrice) ?? 0,
                  };

                  try {
                    if (isEditing) {
                      await _service.updateService(service['_id'], data);
                    } else {
                      await _service.createService(data);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _refreshServices();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isEditing
                            ? "Service updated"
                            : "Service created")));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                }
              },
              child: Text(isEditing ? "Save Changes" : "Create Service",
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
