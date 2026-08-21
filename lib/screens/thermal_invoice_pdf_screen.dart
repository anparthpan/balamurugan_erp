import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class ThermalInvoicePdfScreen extends StatelessWidget {
  final Voucher voucher;
  const ThermalInvoicePdfScreen({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    final data = context.read<BalamuruganData>();
    String title = 'Thermal Bill Preview';
    if (voucher.type == VoucherType.quotation) title = 'Quotation Preview';
    else if (voucher.type == VoucherType.proforma) title = 'Proforma Preview';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, voucher, data),
        canDebug: false,
        initialPageFormat: PdfPageFormat.roll80,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, Voucher voucher, BalamuruganData data) async {
    final pdf = pw.Document();
    final company = data.currentCompany;
    
    // 80mm thermal paper format
    const thermalFormat = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);

    String idPrefix = 'INV';
    if (voucher.type == VoucherType.quotation) idPrefix = 'QTN';
    else if (voucher.type == VoucherType.proforma) idPrefix = 'PRO';
    else if (voucher.type == VoucherType.purchase) idPrefix = 'PUR';

    pdf.addPage(
      pw.Page(
        pageFormat: thermalFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(company.name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(company.address, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Phone: ${company.phone}', style: const pw.TextStyle(fontSize: 8)),
              if (company.gstin.isNotEmpty) pw.Text('GSTIN: ${company.gstin}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              ),

              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$idPrefix: ${voucher.id.split('-').last}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(DateFormat('dd-MM-yy HH:mm').format(voucher.date), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('CUST: ${voucher.ledgerName.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Divider(thickness: 0.5),
              ),

              // Items Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FixedColumnWidth(20),
                  2: const pw.FixedColumnWidth(40),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      pw.Text('Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ],
                  ),
                  ...voucher.items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.description, style: const pw.TextStyle(fontSize: 8)),
                            if (item.serialNumber.isNotEmpty) pw.Text('S/N: ${item.serialNumber}', style: const pw.TextStyle(fontSize: 7)),
                          ],
                        ),
                      ),
                      pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                      pw.Text(item.amount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                    ],
                  )),
                ],
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              ),

              // Totals
              _totalRow('Sub Total', voucher.amount.toStringAsFixed(2)),
              if (company.isGstEnabled) ...[
                _totalRow('CGST (9%)', (voucher.amount * 0.09).toStringAsFixed(2)),
                _totalRow('SGST (9%)', (voucher.amount * 0.09).toStringAsFixed(2)),
              ],
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Rs. ${company.isGstEnabled ? (voucher.amount * 1.18).toStringAsFixed(2) : voucher.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),
              
              // QR Code
              if (company.upiId.isNotEmpty) ...[
                pw.BarcodeWidget(
                  data: 'upi://pay?pa=${company.upiId}&pn=${company.name}&am=${(company.isGstEnabled ? voucher.amount * 1.18 : voucher.amount).toStringAsFixed(2)}&cu=INR',
                  barcode: pw.Barcode.qrCode(),
                  width: 60,
                  height: 60,
                ),
                pw.SizedBox(height: 4),
                pw.Text('SCAN TO PAY', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ],

              pw.SizedBox(height: 20),
              pw.Text('THANK YOU! VISIT AGAIN', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}
