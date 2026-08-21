import 'package:flutter/material.dart';

class CreateMasterScreen extends StatelessWidget {
  final Function(String)? onAction;
  const CreateMasterScreen({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('MASTERS CREATION'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('ACCOUNTING MASTERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _modernTile(
                context, 
                title: 'Ledger', 
                subtitle: 'Create Customer, Supplier or Expense accounts',
                icon: Icons.person_add_outlined,
                onTap: () => onAction?.call('ledger_entry')
              ),
              const SizedBox(height: 24),
              const Text('INVENTORY MASTERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _modernTile(
                context, 
                title: 'Stock Item', 
                subtitle: 'Create products or items for inventory',
                icon: Icons.inventory_2_outlined,
                onTap: () => onAction?.call('stock_item_entry')
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modernTile(BuildContext context, {required String title, required String subtitle,  required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),

        onTap: onTap,
      ),
    );
  }
}
