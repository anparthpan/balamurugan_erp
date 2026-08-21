import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';

class AgeingReportScreen extends StatelessWidget {
  const AgeingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    final ageing = data.ageingReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OUTSTANDING AGEING REPORT'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: ageing.entries.map((bucket) {
                  if (bucket.value.isEmpty) return const SizedBox.shrink();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Text(
                            bucket.key.toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                          ),
                        ),
                        ...bucket.value.entries.map((entry) => ListTile(
                          title: Text(entry.key),
                          trailing: Text(
                            '₹ ${entry.value.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
