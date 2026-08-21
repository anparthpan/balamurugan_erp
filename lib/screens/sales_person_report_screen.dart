import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';

class SalesPersonReportScreen extends StatelessWidget {
  const SalesPersonReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    final stats = data.salesByPerson;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SALES PERSON PERFORMANCE'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SALES SUMMARY BY EXECUTIVE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: stats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No sales records found', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final name = stats.keys.elementAt(index);
                        final totalSales = stats[name]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                            ),
                            title: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Executive Sales Achievement'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹ ${totalSales.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.blue),
                                ),
                                Text(
                                  'Comm: ₹ ${(totalSales * 0.02).toStringAsFixed(2)} (2%)',
                                  style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
