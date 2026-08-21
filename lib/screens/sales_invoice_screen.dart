import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models.dart';
import '../balamurugan_data.dart';
import 'invoice_pdf_screen.dart';

class SalesInvoiceScreen extends StatelessWidget {
  final Voucher voucher;
  const SalesInvoiceScreen({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Consumer<BalamuruganData>(
      builder: (context, data, _) {
        final company = data.currentCompany;
        final currentVoucher = data.vouchers.firstWhere((v) => v.id == voucher.id, orElse: () => voucher);

        double subTotal = currentVoucher.items.fold(0, (sum, item) => sum + item.amount);
        if (subTotal == 0) subTotal = currentVoucher.amount;

        double cgst = company.isGstEnabled ? subTotal * 0.09 : 0;
        double sgst = company.isGstEnabled ? subTotal * 0.09 : 0;
        double total = subTotal + cgst + sgst;

        final buyer = data.findLedger(currentVoucher.ledgerName);
        final displayAddress = currentVoucher.customerAddress ?? buyer?.address ?? 'Address Details Placeholder\nCity, State, PIN';

        String title = 'INVOICE';
        if (currentVoucher.type == VoucherType.quotation) title = 'QUOTATION';
        if (currentVoucher.type == VoucherType.proforma) title = 'PROFORMA INVOICE';

        return Column(
          children: [
            AppBar(
              title: Text(title),
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              automaticallyImplyLeading: false,
              actions: [
                if (currentVoucher.type == VoucherType.sales)
                  TextButton.icon(
                    onPressed: () => data.togglePaymentStatus(currentVoucher.id),
                    icon: Icon(currentVoucher.isPaid ? Icons.check_circle : Icons.pending_actions, color: currentVoucher.isPaid ? Colors.green : Colors.orange),
                    label: Text(currentVoucher.isPaid ? 'RECEIVED' : 'DUE', style: TextStyle(color: currentVoucher.isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InvoicePdfScreen(voucher: currentVoucher)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                )
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 800,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        padding: const EdgeInsets.all(50),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (company.logoBase64 != null)
                                      Image.memory(base64Decode(company.logoBase64!), width: 80, height: 80, fit: BoxFit.contain)
                                    else
                                      Container(
                                        width: 80, height: 80,
                                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(12)),
                                        child: Center(child: Text(company.name[0], style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
                                      ),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(company.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                                        const SizedBox(height: 4),
                                        SizedBox(width: 300, child: Text(company.address, style: const TextStyle(fontSize: 11, color: Colors.black87))),
                                        if (company.gstin.isNotEmpty) Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text('GSTIN: ${company.gstin}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        Text('Contact: ${company.phone}', style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(title, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.grey.shade300, letterSpacing: 2)),
                                    const SizedBox(height: 10),
                                    _infoLabel(
                                      currentVoucher.type == VoucherType.quotation ? 'Quotation #' : 
                                      currentVoucher.type == VoucherType.proforma ? 'Proforma #' : 'Invoice #', 
                                      currentVoucher.id.substring(currentVoucher.id.length > 8 ? currentVoucher.id.length - 8 : 0).toUpperCase()
                                    ),
                                    _infoLabel('Date', DateFormat('dd-MMM-yyyy').format(currentVoucher.date)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            // Bill To
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('BILL TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                      const SizedBox(height: 10),
                                      Text(currentVoucher.ledgerName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(displayAddress, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      if (currentVoucher.customerPhone != null) Text('Phone: ${currentVoucher.customerPhone}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            // Items Table
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Table(
                                  columnWidths: const {
                                    0: FixedColumnWidth(40),
                                    1: FlexColumnWidth(),
                                    2: FixedColumnWidth(70),
                                    3: FixedColumnWidth(70),
                                    4: FixedColumnWidth(90),
                                    5: FixedColumnWidth(110),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: Colors.grey.shade50),
                                      children: [
                                        _th('#'),
                                        _th('DESCRIPTION'),
                                        _th('HSN'),
                                        _th('QTY'),
                                        _th('RATE'),
                                        _th('AMOUNT'),
                                      ],
                                    ),
                                    ...currentVoucher.items.asMap().entries.map((entry) {
                                      final item = entry.value;
                                      return TableRow(
                                        children: [
                                          _td('${entry.key + 1}'),
                                          _td(item.description),
                                          _td(item.hsnCode),
                                          _td('${item.quantity} ${item.unit}'),
                                          _td('₹ ${item.rate.toStringAsFixed(2)}'),
                                          _td('₹ ${item.amount.toStringAsFixed(2)}', bold: true),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Totals
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: Column(
                                    children: [
                                      _totalRow('Sub Total', subTotal),
                                      if (company.isGstEnabled) ...[
                                        _totalRow('CGST (9%)', cgst),
                                        _totalRow('SGST (9%)', sgst),
                                      ],
                                      const Divider(height: 30),
                                      _totalRow('GRAND TOTAL', total, isGrand: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 60),
                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Company Bank Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline)),
                                            const SizedBox(height: 8),
                                            Text('Name: ${company.beneficiaryName.isNotEmpty ? company.beneficiaryName : company.name}', style: const TextStyle(fontSize: 11)),
                                            Text('Ac/No: ${company.accNo}', style: const TextStyle(fontSize: 11)),
                                            Text('IFSC: ${company.ifsc}', style: const TextStyle(fontSize: 11)),
                                            Text('Bank: ${company.bankName}', style: const TextStyle(fontSize: 11)),
                                          ],
                                        ),
                                        if (company.upiId.isNotEmpty)
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              BarcodeWidget(
                                                data: 'upi://pay?pa=${company.upiId}&pn=${company.name}&am=${total.toStringAsFixed(2)}&cu=INR',
                                                barcode: Barcode.qrCode(),
                                                width: 60,
                                                height: 60,
                                              ),
                                              const SizedBox(height: 4),
                                              const Text('SCAN TO PAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 40),
                                Column(
                                  children: [
                                    const Text('Authorized Signatory', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 40),
                                    Container(width: 150, height: 1, color: Colors.black26),
                                    const SizedBox(height: 8),
                                    Text('for ${company.name}', style: const TextStyle(fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (currentVoucher.type == VoucherType.sales)
                        Positioned(
                          top: 150,
                          right: 40,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: (currentVoucher.isPaid ? Colors.green : Colors.red).withValues(alpha: 0.2), width: 4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                currentVoucher.isPaid ? 'RECEIVED' : 'DUE',
                                style: TextStyle(
                                  color: (currentVoucher.isPaid ? Colors.green : Colors.red).withValues(alpha: 0.2),
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _totalRow(String label, double value, {bool isGrand = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isGrand ? 14 : 12, fontWeight: isGrand ? FontWeight.w900 : FontWeight.w500)),
          Text('₹ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: isGrand ? 16 : 12, fontWeight: isGrand ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _th(String label) => Padding(padding: const EdgeInsets.all(12), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54)));
  Widget _td(String label, {bool bold = false}) => Padding(padding: const EdgeInsets.all(12), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.normal)));

  Widget _infoLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
