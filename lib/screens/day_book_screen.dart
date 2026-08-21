import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';
import '../models.dart';
import 'invoice_pdf_screen.dart';
import 'service_pdf_screen.dart';
import 'thermal_invoice_pdf_screen.dart';

class DayBookScreen extends StatefulWidget {
  final Function(Voucher)? onEditVoucher;
  final Function(ServiceJob)? onEditJob;
  const DayBookScreen({super.key, this.onEditVoucher, this.onEditJob});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  String _filter = 'All'; // 'All', 'Due', 'Received'
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
          title: const Text('DAY BOOK'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Consumer<BalamuruganData>(
            builder: (context, data, _) {
              final List<dynamic> allTransactions = [
                ...data.vouchers,
                ...data.serviceJobs,
              ];

              final filtered = allTransactions.where((item) {
                bool isPaid = false;
                bool isCashFlow = false; 
                bool isNonAccounting = false; 
                
                if (item is Voucher) {
                  isPaid = item.isPaid;
                  isCashFlow = item.type == VoucherType.payment || item.type == VoucherType.receipt;
                  isNonAccounting = item.type == VoucherType.quotation || item.type == VoucherType.proforma;
                }
                if (item is ServiceJob) isPaid = item.isPaid;

                bool matchesSearch = true;
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  if (item is Voucher) {
                    matchesSearch = item.ledgerName.toLowerCase().contains(query) || 
                                    item.narration.toLowerCase().contains(query) ||
                                    item.id.toLowerCase().contains(query);
                  } else if (item is ServiceJob) {
                    matchesSearch = item.customerName.toLowerCase().contains(query) || 
                                    item.description.toLowerCase().contains(query) ||
                                    item.jobCode.toLowerCase().contains(query);
                  }
                }

                if (!matchesSearch) return false;

                if (_filter == 'Due') {
                  if (isNonAccounting) return false;
                  return !isPaid && !isCashFlow;
                }
                if (_filter == 'Received') {
                  if (isNonAccounting) return false;
                  return isPaid;
                }
                return true;
              }).toList();

              filtered.sort((a, b) => b.date.compareTo(a.date));

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, narration or ID...',
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('FILTER:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.1)),
                            const SizedBox(width: 15),
                            _filterChip('All'),
                            const SizedBox(width: 10),
                            _filterChip('Due'),
                            const SizedBox(width: 10),
                            _filterChip('Received'),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('${filtered.length} entries', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];

                        if (item is Voucher) {
                          bool isPaid = item.isPaid;
                          IconData icon = isPaid ? Icons.check_circle : Icons.pending_actions;
                          Color statusColor = isPaid ? Colors.green : Colors.orange;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withValues(alpha: 0.1),
                                child: Icon(icon, color: statusColor, size: 20),
                              ),
                              title: Text(item.ledgerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('${item.type.name.toUpperCase()} | ${DateFormat('dd MMM yyyy').format(item.date)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹ ${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(isPaid ? 'PAID' : 'DUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.grey),
                                    onPressed: () {
                                      if (widget.onEditVoucher != null) {
                                        widget.onEditVoucher!(item);
                                      }
                                    },
                                    tooltip: 'Edit Entry',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.blue),
                                    onPressed: () => _showPrintOptions(context, item),
                                    tooltip: 'Print Voucher',
                                  ),
                                  if (item.type == VoucherType.sales || item.type == VoucherType.purchase)
                                    IconButton(
                                      icon: Icon(isPaid ? Icons.check_circle : Icons.pending_actions, color: statusColor),
                                      onPressed: () => data.togglePaymentStatus(item.id),
                                      tooltip: isPaid 
                                        ? (item.type == VoucherType.sales ? 'Mark as Due' : 'Mark as Unpaid') 
                                        : (item.type == VoucherType.sales ? 'Mark as Received' : 'Mark as Paid'),
                                    ),
                                ],
                              ),
                              onTap: () {
                                if (widget.onEditVoucher != null) {
                                  widget.onEditVoucher!(item);
                                }
                              },
                            ),
                          );
                        } else if (item is ServiceJob) {
                          bool isPaid = item.isPaid;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                child: const Icon(Icons.build, color: Colors.blue, size: 20),
                              ),
                              title: Text(item.customerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('JOB: ${item.jobCode} | ${DateFormat('dd MMM yyyy').format(item.date)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹ ${item.amountCharged.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.blue)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: (isPaid ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(isPaid ? 'PAID' : 'DUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.red)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.grey),
                                    onPressed: () {
                                      if (widget.onEditJob != null) {
                                        widget.onEditJob!(item);
                                      }
                                    },
                                    tooltip: 'Edit Entry',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ServicePdfScreen(job: item)));
                                    },
                                    tooltip: 'Print Service Bill',
                                  ),
                                  IconButton(
                                    icon: Icon(isPaid ? Icons.check_circle : Icons.pending_actions, color: isPaid ? Colors.green : Colors.red),
                                    onPressed: () => data.toggleServicePaymentStatus(item.jobCode),
                                    tooltip: isPaid ? 'Mark as Due' : 'Mark as Paid',
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (widget.onEditJob != null) {
                                  widget.onEditJob!(item);
                                }
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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

  Widget _filterChip(String label) {
    bool selected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11, 
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? Colors.white : Colors.black87,
      ),
      selected: selected,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (val) {
        if (val) setState(() => _filter = label);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _showPrintOptions(BuildContext context, Voucher voucher) {
    String docType = 'Invoice';
    if (voucher.type == VoucherType.quotation) docType = 'Quotation';
    else if (voucher.type == VoucherType.proforma) docType = 'Proforma';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('CHOOSE PRINT FORMAT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, color: Colors.blue),
              ),
              title: Text('A4 Professional $docType', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Best for ${voucher.type == VoucherType.quotation ? 'sharing with clients' : 'corporate customers and GST filing'}'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => InvoicePdfScreen(voucher: voucher)));
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_outlined, color: Colors.orange),
              ),
              title: const Text('Thermal Bill (80mm)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Quick counter receipt with payment QR'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ThermalInvoicePdfScreen(voucher: voucher)));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
