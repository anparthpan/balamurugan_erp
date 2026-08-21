import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';
import 'statement_pdf_screen.dart';

class CustomerStatementScreen extends StatefulWidget {
  const CustomerStatementScreen({super.key});

  @override
  State<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  String? _selectedCustomer;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    final customers = data.ledgers.map((l) => l.name).toList();
    
    final statement = _selectedCustomer == null 
        ? <Map<String, dynamic>>[] 
        : data.getCustomerStatement(_selectedCustomer!, _startDate, _endDate);

    double totalBilled = 0;
    double totalReceived = 0;
    for (var row in statement) {
      totalBilled += (row['billed'] as double);
      totalReceived += (row['received'] as double);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOMER WISE STATEMENT'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        actions: [
          if (_selectedCustomer != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                final data = context.read<BalamuruganData>();
                final statement = data.getCustomerStatement(_selectedCustomer!, _startDate, _endDate);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatementPdfScreen(
                      customerName: _selectedCustomer!,
                      startDate: _startDate,
                      endDate: _endDate,
                      statement: statement,
                    ),
                  ),
                );
              },
              tooltip: 'Print Statement',
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCustomer,
                        hint: const Text('Select Customer'),
                        isExpanded: true,
                        items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCustomer = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text('${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedCustomer == null 
              ? const Center(child: Text('Please select a customer to view statement'))
              : statement.isEmpty 
                ? const Center(child: Text('No transactions found in this period'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Particulars')),
                        DataColumn(label: Text('Billed (Dr)')),
                        DataColumn(label: Text('Received (Cr)')),
                      ],
                      rows: [
                        ...statement.map((row) => DataRow(cells: [
                          DataCell(Text(DateFormat('dd-MMM-yy').format(row['date']))),
                          DataCell(Text(row['particulars'])),
                          DataCell(Text(row['billed'] > 0 ? '₹ ${row['billed'].toStringAsFixed(2)}' : '')),
                          DataCell(Text(row['received'] > 0 ? '₹ ${row['received'].toStringAsFixed(2)}' : '')),
                        ])),
                        DataRow(
                          color: WidgetStateProperty.all(Colors.grey.shade100),
                          cells: [
                            const DataCell(Text('')),
                            const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('₹ ${totalBilled.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('₹ ${totalReceived.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('OUTSTANDING BALANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    '₹ ${(totalBilled - totalReceived).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
