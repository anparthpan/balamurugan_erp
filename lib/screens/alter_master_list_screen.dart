import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class AlterMasterListScreen extends StatefulWidget {
  final Function(Master, int)? onEditLedger;
  final Function(StockItem, int)? onEditStockItem;
  const AlterMasterListScreen({super.key, this.onEditLedger, this.onEditStockItem});

  @override
  State<AlterMasterListScreen> createState() => _AlterMasterListScreenState();
}

class _AlterMasterListScreenState extends State<AlterMasterListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('ALTER MASTERS'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search masters...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: Consumer<BalamuruganData>(
            builder: (context, data, _) {
              final query = _searchQuery.toLowerCase();
              final filteredLedgers = data.ledgers.asMap().entries.where((e) => 
                e.value.name.toLowerCase().contains(query) || e.value.group.toLowerCase().contains(query)).toList();

              final filteredStockItems = data.stockItems.asMap().entries.where((e) =>
                e.value.name.toLowerCase().contains(query)).toList();

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (filteredLedgers.isNotEmpty) ...[
                    const Text('LEDGERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    ...filteredLedgers.map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.person_outline, color: Colors.blue),
                        ),
                        title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(e.value.group, style: const TextStyle(fontSize: 12)),
                        onTap: () => widget.onEditLedger?.call(e.value, e.key),
                      ),
                    )),
                    const SizedBox(height: 30),
                  ],
                  if (filteredStockItems.isNotEmpty) ...[
                    const Text('STOCK ITEMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    ...filteredStockItems.map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade50,
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
                        ),
                        title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Opening: ${e.value.openingBalance}', style: const TextStyle(fontSize: 12)),
                        onTap: () => widget.onEditStockItem?.call(e.value, e.key),
                      ),
                    )),
                  ],
                  if (filteredLedgers.isEmpty && filteredStockItems.isEmpty)
                    const Center(child: Text('No results found', style: TextStyle(color: Colors.grey))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
