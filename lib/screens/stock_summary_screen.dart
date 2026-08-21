import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';

class StockSummaryScreen extends StatelessWidget {
  const StockSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('STOCK SUMMARY'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Consumer<BalamuruganData>(
            builder: (context, data, _) {
              final summary = data.stockSummary;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text('TOTAL ITEMS', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            Text('${summary.length}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const Text('INVENTORY STATUS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('ITEM NAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                                    Expanded(flex: 1, child: Text('QUANTITY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey), textAlign: TextAlign.right)),
                                  ],
                                ),
                              ),
                              if (summary.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Text('No items in stock', style: TextStyle(color: Colors.grey)),
                                ),
                              ...summary.entries.map((entry) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3, 
                                      child: Text(entry.key.toUpperCase(), 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                                    ),
                                    Expanded(
                                      flex: 1, 
                                      child: Text('${entry.value} Nos', 
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900, 
                                          fontSize: 14,
                                          color: entry.value < 0 ? Colors.red : Colors.green.shade700
                                        ), textAlign: TextAlign.right)
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
