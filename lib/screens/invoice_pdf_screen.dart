import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';
import '../utils.dart';

class InvoicePdfScreen extends StatelessWidget {
  final Voucher voucher;
  const InvoicePdfScreen({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    final data = context.read<BalamuruganData>();
    String appBarTitle = 'Print Preview';
    if (voucher.type == VoucherType.quotation) appBarTitle = 'Quotation Preview';
    else if (voucher.type == VoucherType.proforma) appBarTitle = 'Proforma Preview';
    else if (voucher.type == VoucherType.sales) appBarTitle = 'Sales Invoice Preview';
    else if (voucher.type == VoucherType.purchase) appBarTitle = 'Purchase Invoice Preview';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, voucher, data),
        canDebug: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, Voucher voucher, BalamuruganData data) async {
    final pdf = pw.Document();
    final company = data.currentCompany;
    final isGst = company.isGstEnabled;

    final logoImage = company.logoBase64 != null 
        ? pw.MemoryImage(base64Decode(company.logoBase64!)) 
        : pw.MemoryImage((await rootBundle.load('assets/logo.png')).buffer.asUint8List());

    // Generate Copies
    List<String> copies = [];
    if (voucher.type == VoucherType.quotation) {
      copies = ['QUOTATION'];
    } else if (voucher.type == VoucherType.proforma) {
      copies = ['PROFORMA INVOICE'];
    } else {
      copies = ['ORIGINAL FOR RECIPIENT', 'DUPLICATE FOR SUPPLIER'];
    }
    
    for (var copyLabel in copies) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: _buildPageContent(voucher, data, company, isGst, logoImage, copyLabel),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  List<pw.Widget> _buildPageContent(Voucher voucher, BalamuruganData data, Company company, bool isGst, pw.MemoryImage logoImage, String copyLabel) {
    final subTotal = voucher.items.fold(0.0, (sum, item) => sum + item.amount);
    final cgst = isGst ? subTotal * 0.09 : 0.0;
    final sgst = isGst ? subTotal * 0.09 : 0.0;
    final total = subTotal + cgst + sgst;
    final rounding = (total.roundToDouble() - total).abs() < 0.01 ? 0.0 : total.roundToDouble() - total;
    final grandTotal = total + rounding;

    final buyer = data.findLedger(voucher.ledgerName);
    final displayAddress = voucher.customerAddress ?? buyer?.address ?? 'Address details not provided';

    String docTitle = '';
    String idLabel = '';
    String dateLabel = '';

    if (voucher.type == VoucherType.quotation) {
      docTitle = 'QUOTATION';
      idLabel = 'Quotation No #';
      dateLabel = 'Quotation Date';
    } else if (voucher.type == VoucherType.proforma) {
      docTitle = 'PROFORMA INVOICE';
      idLabel = 'Proforma No #';
      dateLabel = 'Proforma Date';
    } else {
      docTitle = isGst ? 'TAX INVOICE' : 'INVOICE';
      idLabel = voucher.type == VoucherType.purchase ? 'Purchase No #' : 'Invoice No #';
      dateLabel = voucher.type == VoucherType.purchase ? 'Purchase Date' : 'Invoice Date';
    }

    return [
      // 0. COPY LABEL
      if (voucher.type != VoucherType.quotation && voucher.type != VoucherType.proforma)
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Text(copyLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        ),
      pw.SizedBox(height: 5),

      // 1. HEADER SECTION
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
        child: pw.Column(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Image(logoImage, width: 50, height: 50),
                            pw.SizedBox(width: 10),
                            pw.Text(company.name.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          ],
                        ),
                        pw.Text('All Brands of Desktops, Laptops and Printers Sales and Service. CCTV Sales & Installation', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                        pw.SizedBox(height: 5),
                        pw.Text(company.address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                        if (company.gstin.isNotEmpty) pw.Text('GSTIN ${company.gstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.Text('Phone - ${company.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(docTitle, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ),
                ],
              ),
            ),
            
            // 2. METADATA GRID
            pw.Divider(height: 1, color: PdfColors.black),
            pw.Table(
              border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
              columnWidths: {
                0: const pw.FlexColumnWidth(),
                1: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Column(
                      children: [
                        _metaRow(idLabel, ': ${voucher.id.length > 8 ? voucher.id.substring(voucher.id.length - 8) : voucher.id}'),
                        _metaRow(dateLabel, ': ${DateFormat('dd/MM/yyyy').format(voucher.date)}'),
                        _metaRow('Terms', ': Immediate'),
                        _metaRow('Due Date', ': ${DateFormat('dd/MM/yyyy').format(voucher.date)}'),
                        _metaRow('P.O.#', ': '),
                      ],
                    ),
                    pw.Column(
                      children: [
                        _metaRow('Place Of Supply', ': Tamil Nadu (33)'),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // 3. BILL TO / SHIP TO
            pw.Divider(height: 1, color: PdfColors.black),
            pw.Table(
              border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
              columnWidths: {
                0: const pw.FlexColumnWidth(),
                1: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      color: PdfColors.grey100,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Bill To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
                    ),
                    pw.Container(
                      color: PdfColors.grey100,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Ship To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(height: 1, color: PdfColors.black),
            pw.Table(
              border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
              columnWidths: {
                0: const pw.FlexColumnWidth(),
                1: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(voucher.ledgerName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                          pw.Text(displayAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                          if (buyer?.phone.isNotEmpty ?? false) pw.Text('Phone: ${buyer!.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                          if (buyer?.gstin.isNotEmpty ?? false) pw.Text('GSTIN: ${buyer!.gstin}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(voucher.ledgerName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                          pw.Text(displayAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 10),

      // 4. ITEM TABLE
      pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Table(
            border: const pw.TableBorder(
              verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
            ),
            columnWidths: isGst ? {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FlexColumnWidth(5),
              2: const pw.FixedColumnWidth(40),
              3: const pw.FixedColumnWidth(30),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FixedColumnWidth(35),
              6: const pw.FixedColumnWidth(50),
              7: const pw.FixedColumnWidth(35),
              8: const pw.FixedColumnWidth(50),
              9: const pw.FixedColumnWidth(60),
            } : {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(60),
              3: const pw.FixedColumnWidth(40),
              4: const pw.FixedColumnWidth(80),
              5: const pw.FixedColumnWidth(80),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
              ),
              children: isGst ? [
                  _tableH('#'),
                  _tableH('Item & Description / Serial No.'),
                  _tableH('HSN/SAC'),
                  _tableH('Qty'),
                  _tableH('Rate'),
                  _tableH('CGST %'),
                  _tableH('CGST Amt'),
                  _tableH('SGST %'),
                  _tableH('SGST Amt'),
                  _tableH('Amount'),
                ] : [
                  _tableH('#'),
                  _tableH('Item & Description'),
                  _tableH('Serial No.'),
                  _tableH('Qty'),
                  _tableH('Rate'),
                  _tableH('Amount'),
                ],
              ),
              // Data Rows
              ...voucher.items.asMap().entries.map((e) {
                final i = e.key + 1;
                final item = e.value;
                final itemCgst = isGst ? item.amount * 0.09 : 0.0;
                final itemSgst = isGst ? item.amount * 0.09 : 0.0;

                return pw.TableRow(
                  children: isGst ? [
                    _tableD('$i'),
                    _pdfDescriptionCell(item.description, serial: item.serialNumber),
                    _tableD(item.hsnCode),
                    _tableD('${item.quantity}'),
                    _tableD(item.rate.toStringAsFixed(2)),
                    _tableD('9%'),
                    _tableD(itemCgst.toStringAsFixed(2)),
                    _tableD('9%'),
                    _tableD(itemSgst.toStringAsFixed(2)),
                    _tableD(item.amount.toStringAsFixed(2), align: pw.TextAlign.right, bold: true),
                  ] : [
                    _tableD('$i'),
                    _pdfDescriptionCell(item.description),
                    _tableD(item.serialNumber),
                    _tableD('${item.quantity}'),
                    _tableD(item.rate.toStringAsFixed(2)),
                    _tableD(item.amount.toStringAsFixed(2), align: pw.TextAlign.right, bold: true),
                  ],
                );
              }),
            ],
          ),
        ),
      ),

      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.black, width: 0.5),
            right: pw.BorderSide(color: PdfColors.black, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
        child: pw.Table(
          border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total In Words', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      pw.Text('${numberToWords(grandTotal)} Only', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, color: PdfColors.black)),
                      pw.SizedBox(height: 15),
                      pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 8, decoration: pw.TextDecoration.underline, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      if (voucher.type == VoucherType.quotation || voucher.type == VoucherType.proforma) ...[
                        pw.Text('1. This is a computer generated document and valid for 7 days.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                        pw.Text('2. Prices and availability are subject to change without notice.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      ] else ...[
                        pw.Text('1. Goods once sold cannot be taken back/ Exchange due to any reasons.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                        pw.Text('2. Product warranty terms & conditions as per the manufacturer\'s warranty.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      ],
                      pw.Text('3. Subject to Tamil Nadu Jurisdiction.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                    ],
                  ),
                ),
                pw.Column(
                  children: [
                    _calcRow('Sub Total', subTotal.toStringAsFixed(2)),
                    if (isGst) ...[
                      _calcRow('CGST9 (9%)', cgst.toStringAsFixed(2)),
                      _calcRow('SGST9 (9%)', sgst.toStringAsFixed(2)),
                    ],
                    _calcRow('Rounding', rounding.toStringAsFixed(2)),
                    pw.Container(
                      color: PdfColors.grey100,
                      child: _calcRow('Total', grandTotal.toStringAsFixed(2), bold: true, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // 6. BOTTOM SECTION (Bank, Signature)
      pw.SizedBox(height: 15),
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
        child: pw.Table(
          border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Company Bank Details:', style: pw.TextStyle(fontSize: 8, decoration: pw.TextDecoration.underline, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('Name: ${company.beneficiaryName.isNotEmpty ? company.beneficiaryName : company.name}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('Ac/No : ${company.accNo}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('IFSC : ${company.ifsc}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('Bank Name: ${company.bankName}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ],
                      ),
                      if (company.upiId.isNotEmpty)
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              data: 'upi://pay?pa=${company.upiId}&pn=${company.name}&am=${grandTotal.toStringAsFixed(2)}&cu=INR',
                              barcode: pw.Barcode.qrCode(),
                              width: 50,
                              height: 50,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text('SCAN TO PAY', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('For BALAMURUGAN ENTERPRISES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.SizedBox(height: 5),
                      pw.Container(width: 120, height: 30, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed))),
                      pw.SizedBox(height: 5),
                      pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _tableH(String text) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5), child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.black)));
  
  pw.Widget _tableD(String text, {pw.TextAlign align = pw.TextAlign.center, bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 5),
    child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black))
  );

  pw.Widget _pdfDescriptionCell(String text, {String? serial}) {
    String header = '';
    String specs = '';

    if (text.contains('\n')) {
      final lines = text.split('\n');
      header = lines[0].trim();
      specs = lines.sublist(1).join('\n').trim();
    } else if (text.contains(',')) {
      final commaIndex = text.indexOf(',');
      header = text.substring(0, commaIndex).trim();
      specs = text.substring(commaIndex + 1).trim();
    } else {
      header = text.trim();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(header.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
          if (specs.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(specs, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          ],
          if (serial != null && serial.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Serial No: $serial', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          ],
          pw.SizedBox(height: 25), // Increased breathing room at the bottom
        ],
      ),
    );
  }

  pw.Widget _calcRow(String label, String value, {bool bold = false, double fontSize = 9}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black)),
        ],
      ),
    );
  }
}
