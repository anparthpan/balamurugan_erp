import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('BALANCE SHEET'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Consumer<BalamuruganData>(
            builder: (context, data, _) {
              final partyData = data.partyBalances;
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        const Text('NET CASH BALANCE', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text('₹ ${data.cashBalance.toStringAsFixed(2)}', 
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, letterSpacing: -1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const Text('PARTY WISE BALANCES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey))),
                                    Expanded(flex: 2, child: Text('RECEIVED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey), textAlign: TextAlign.right)),
                                    Expanded(flex: 2, child: Text('DUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey), textAlign: TextAlign.right)),
                                  ],
                                ),
                              ),
                              ...partyData.map((party) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3, 
                                      child: Text(party['name'].toString().toUpperCase(), 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                                    ),
                                    Expanded(
                                      flex: 2, 
                                      child: Text('₹ ${party['received'].toStringAsFixed(2)}', 
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.right)
                                    ),
                                    Expanded(
                                      flex: 2, 
                                      child: Text('₹ ${party['due'].toStringAsFixed(2)}', 
                                        style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.right)
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
