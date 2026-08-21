import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';

class ProfitLossScreen extends StatelessWidget {
  const ProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('PROFIT & LOSS A/C'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Consumer<BalamuruganData>(
            builder: (context, data, _) {
              final profitData = data.profitLossData;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modernSection(context, 'TRADING ACCOUNT', [
                      _row('Sales (Product)', profitData['Sales Accounts']!),
                      _row('Service Charges', profitData['Service Charges']!),
                      _row('Purchase Accounts', profitData['Purchase Accounts']!, isExpense: true),
                    ]),
                    const SizedBox(height: 24),
                    _modernSection(context, 'INCOME & EXPENSES', [
                      _row('Indirect Incomes', profitData['Indirect Incomes']!),
                      _row('Indirect Expenses', profitData['Indirect Expenses']!, isExpense: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Divider(height: 1),
                      ),
                      _row('NET PROFIT', profitData['Net Profit']!, isBold: true, isFinal: true),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _modernSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool isExpense = false, bool isBold = false, bool isFinal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isFinal ? 18 : 14,
            color: isFinal ? Colors.black : Colors.black87,
          )),
          Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isFinal ? 20 : 15,
              color: isFinal 
                ? (value >= 0 ? Colors.green.shade700 : Colors.red)
                : (isExpense ? Colors.red.shade700 : Colors.green.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
