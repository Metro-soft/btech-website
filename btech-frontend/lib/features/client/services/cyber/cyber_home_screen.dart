import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CyberHomeScreen extends StatelessWidget {
  const CyberHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cyber Services')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ServiceCard(
            title: 'KUCCPS Application',
            description: 'University & College Placement',
            icon: Icons.school,
            color: Colors.blue.shade100,
            onTap: () => context.go('/cyber/kuccps'),
          ),
          const SizedBox(height: 16),
          _ServiceCard(
            title: 'HELB Loan',
            description: 'First Time & Subsequent Loans',
            icon: Icons.monetization_on,
            color: Colors.green.shade100,
            onTap: () => context.go('/cyber/helb'),
          ),
          const SizedBox(height: 16),
          _ServiceCard(
            title: 'KRA Services',
            description: 'Returns, PIN, Compliance',
            icon: Icons.receipt_long,
            color: Colors.red.shade100,
            onTap: () => context.go('/cyber/kra'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
