import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';
import 'invoice_pdf_screen.dart';
import 'thermal_invoice_pdf_screen.dart';

class VoucherEntryScreen extends StatefulWidget {
  final Voucher? existingVoucher; // For editing
  final VoucherType? initialType;
  final VoidCallback? onActionDone;
  const VoucherEntryScreen({super.key, this.existingVoucher, this.initialType, this.onActionDone});

  @override
  State<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _VoucherEntryScreenState extends State<VoucherEntryScreen> {
  late VoucherType _type;
  late DateTime _selectedDate;
  final _ledgerController = TextEditingController();
  final _narrationController = TextEditingController();
  final _salesPersonController = TextEditingController();
  final List<ItemRowControllers> _itemRows = [];
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _narrationFocusNode = FocusNode();

  bool get _isInvoiceLayout => 
    _type == VoucherType.sales || 
    _type == VoucherType.purchase || 
    _type == VoucherType.quotation || 
    _type == VoucherType.proforma;

  void _switchType(VoucherType t) => setState(() {
    _type = t;
    if (!_isInvoiceLayout) {
      if (_itemRows.length != 1) {
        for (var row in _itemRows) {
          row.dispose();
        }
        _itemRows.clear();
        _addItem();
      }
    } else if (_itemRows.isEmpty) {
      _addItem();
    }
  });

  void _addItem({String desc = '', String hsn = '', String sn = '', String qty = '', String rate = ''}) {
    setState(() {
      _itemRows.add(ItemRowControllers(
        desc: desc,
        hsn: hsn,
        sn: sn,
        qty: qty,
        rate: rate,
      ));
    });
  }

  void _removeItem(int index) {
    if (_itemRows.length <= 1) return;
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingVoucher != null) {
      final v = widget.existingVoucher!;
      _type = v.type;
      _selectedDate = v.date;
      _ledgerController.text = v.ledgerName;
      _narrationController.text = v.narration;
      _salesPersonController.text = v.salesPerson;
      if (v.items.isNotEmpty) {
        for (var item in v.items) {
          _addItem(
            desc: item.description,
            hsn: item.hsnCode,
            sn: item.serialNumber,
            qty: item.quantity.toString(),
            rate: item.rate.toString(),
          );
        }
      } else {
        _addItem(rate: v.amount.toString());
      }
    } else {
      _type = widget.initialType ?? VoucherType.sales;
      _selectedDate = DateTime.now();
      _addItem();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(VoucherEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialType != oldWidget.initialType && widget.initialType != null) {
      setState(() {
        _type = widget.initialType!;
        // Also reset items if switching type while creating new
        if (widget.existingVoucher == null) {
          for (var row in _itemRows) {
            row.dispose();
          }
          _itemRows.clear();
          _addItem();
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _ledgerController.dispose();
    _narrationController.dispose();
    _salesPersonController.dispose();
    _keyboardFocusNode.dispose();
    _narrationFocusNode.dispose();
    for (var row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.f4: _switchType(VoucherType.contra); break;
        case LogicalKeyboardKey.f5: _switchType(VoucherType.payment); break;
        case LogicalKeyboardKey.f6: _switchType(VoucherType.receipt); break;
        case LogicalKeyboardKey.f7: _switchType(VoucherType.journal); break;
        case LogicalKeyboardKey.f8: _switchType(VoucherType.sales); break;
        case LogicalKeyboardKey.f9: _switchType(VoucherType.purchase); break;
        case LogicalKeyboardKey.f11: _switchType(VoucherType.quotation); break;
        case LogicalKeyboardKey.f12: _switchType(VoucherType.proforma); break;
        case LogicalKeyboardKey.escape: widget.onActionDone?.call(); break;
      }
      if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
        _save();
      }
    }
  }

  void _save() {
    final data = context.read<BalamuruganData>();
    if (_ledgerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Party/Ledger Name')));
      return;
    }

    final List<LineItem> items = [];
    double total = 0;

    if (_isInvoiceLayout) {
      for (var row in _itemRows) {
        final desc = row.descController.text;
        final hsn = row.hsnController.text;
        final sn = row.snController.text;
        final qty = double.tryParse(row.qtyController.text) ?? 0;
        final rate = double.tryParse(row.rateController.text) ?? 0;
        if (desc.isNotEmpty && qty > 0) {
          final item = LineItem(description: desc, hsnCode: hsn, serialNumber: sn, quantity: qty, rate: rate);
          items.add(item);
          total += item.amount;
        }
      }
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item with Quantity > 0')));
        return;
      }
    } else {
      if (_itemRows.isNotEmpty) {
        total = double.tryParse(_itemRows.first.rateController.text) ?? 0;
      }
      if (total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Amount')));
        return;
      }
    }

    final ledger = data.ledgers.firstWhere(
      (l) => l.name == _ledgerController.text,
      orElse: () => Master(name: _ledgerController.text, group: 'Customers'),
    );

    bool defaultPaid = (_type == VoucherType.payment || _type == VoucherType.receipt);

    final voucher = Voucher(
      id: widget.existingVoucher?.id ?? data.getNextVoucherNumber(_type),
      date: _selectedDate,
      ledgerName: _ledgerController.text,
      customerAddress: ledger.address,
      customerPhone: ledger.phone,
      amount: total,
      type: _type,
      narration: _narrationController.text,
      salesPerson: _salesPersonController.text,
      items: items,
      isPaid: widget.existingVoucher?.isPaid ?? defaultPaid,
    );

    try {
      if (widget.existingVoucher == null) {
        data.addVoucher(voucher);
      } else {
        data.updateVoucher(voucher.id, voucher);
      }
      widget.onActionDone?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving voucher: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          AppBar(
            title: Text(widget.existingVoucher == null ? '${_type.name.toUpperCase()} ENTRY' : 'ALTER ${_type.name.toUpperCase()}'),
            elevation: 2,
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            automaticallyImplyLeading: false,
            actions: [
              if (widget.existingVoucher != null) ...[
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.blue),
                  onPressed: () => _showPrintOptions(context, widget.existingVoucher!),
                  tooltip: 'Print Options',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () {
                    context.read<BalamuruganData>().deleteVoucher(widget.existingVoucher!.id);
                    widget.onActionDone?.call();
                  },
                ),
              ],
              const SizedBox(width: 10),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _statusBadge(_type.name.toUpperCase(), _getTypeColor()),
                                const Spacer(),
                                InkWell(
                                  onTap: _selectDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('DATE (Click to change)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        Text(DateFormat('dd-MMM-yyyy').format(_selectedDate), 
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Autocomplete<String>(
                                    optionsBuilder: (v) => context.read<BalamuruganData>().ledgers.map((l) => l.name).where((n) => n.toLowerCase().contains(v.text.toLowerCase())),
                                    onSelected: (v) => _ledgerController.text = v,
                                    fieldViewBuilder: (context, controller, focus, onFieldSubmitted) {
                                      if (controller.text.isEmpty && _ledgerController.text.isNotEmpty) {
                                        controller.text = _ledgerController.text;
                                      }
                                      return TextField(
                                        controller: controller,
                                        focusNode: focus,
                                        onChanged: (v) => _ledgerController.text = v,
                                        decoration: InputDecoration(
                                          labelText: _getPartyLabel(),
                                          prefixIcon: const Icon(Icons.person_outline),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_type == VoucherType.sales) ...[
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _salesPersonController,
                                      decoration: InputDecoration(
                                        labelText: 'Sales Person',
                                        prefixIcon: const Icon(Icons.badge_outlined),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isInvoiceLayout) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ITEM DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                              const SizedBox(height: 20),
                              const Row(
                                children: [
                                  Expanded(flex: 4, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('Serial No.', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                                  SizedBox(width: 50),
                                ],
                              ),
                              const Divider(height: 20),
                              ...List.generate(_itemRows.length, (i) => Padding(
                                key: ValueKey(_itemRows[i]),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4, 
                                      child: Autocomplete<String>(
                                        optionsBuilder: (v) {
                                          final stockItems = context.read<BalamuruganData>().stockItems;
                                          final query = v.text.toLowerCase();
                                          
                                          // Check for exact barcode match first
                                          final barcodeMatch = stockItems.where((s) => s.barcode.isNotEmpty && s.barcode.toLowerCase() == query).toList();
                                          if (barcodeMatch.isNotEmpty) {
                                            // If found via barcode, we can't easily auto-trigger selection here without side effects, 
                                            // but we'll prioritize it in the list.
                                            return barcodeMatch.map((s) => s.name);
                                          }

                                          return stockItems.map((s) => s.name).where((n) => n.toLowerCase().contains(query));
                                        },
                                        onSelected: (v) {
                                          _itemRows[i].descController.text = v;
                                          _itemRows[i].hsnFocusNode.requestFocus();
                                        },
                                        fieldViewBuilder: (context, controller, focus, onFieldSubmitted) {
                                          if (controller.text.isEmpty && _itemRows[i].descController.text.isNotEmpty) {
                                            controller.text = _itemRows[i].descController.text;
                                          }
                                          return TextField(
                                            controller: controller,
                                            focusNode: focus,
                                            maxLines: null,
                                            keyboardType: TextInputType.multiline,
                                            onChanged: (v) => _itemRows[i].descController.text = v,
                                            onSubmitted: (_) => _itemRows[i].hsnFocusNode.requestFocus(),
                                            decoration: const InputDecoration(isDense: true, hintText: 'Item & Specs'),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _itemRows[i].hsnController,
                                        focusNode: _itemRows[i].hsnFocusNode,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) => _itemRows[i].snFocusNode.requestFocus(),
                                        decoration: const InputDecoration(isDense: true, hintText: 'HSN'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _itemRows[i].snController,
                                        focusNode: _itemRows[i].snFocusNode,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) => _itemRows[i].qtyFocusNode.requestFocus(),
                                        decoration: const InputDecoration(isDense: true, hintText: 'S/N'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1, 
                                      child: TextField(
                                        controller: _itemRows[i].qtyController,
                                        focusNode: _itemRows[i].qtyFocusNode,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (v) => setState(() {}),
                                        onSubmitted: (v) => _itemRows[i].rateFocusNode.requestFocus(),
                                        decoration: const InputDecoration(isDense: true, hintText: '0'),
                                      )
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2, 
                                      child: TextField(
                                        controller: _itemRows[i].rateController,
                                        focusNode: _itemRows[i].rateFocusNode,
                                        textAlign: TextAlign.right,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (v) => setState(() {}),
                                        onSubmitted: (v) {
                                          if (i == _itemRows.length - 1) {
                                            _narrationFocusNode.requestFocus();
                                          } else {
                                            _narrationFocusNode.requestFocus();
                                          }
                                        },
                                        decoration: const InputDecoration(isDense: true, hintText: '0.00'),
                                      )
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2, 
                                      child: Text(_itemRows[i].totalAmount.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))
                                    ),
                                    IconButton(onPressed: () => _removeItem(i), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _addItem, 
                                icon: const Icon(Icons.add), 
                                label: const Text('Add Item'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      if (_itemRows.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: _itemRows.first.rateController,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _narrationController, 
                          focusNode: _narrationFocusNode,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Narration / Notes',
                            prefixIcon: Icon(Icons.notes),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _save, 
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          widget.existingVoucher == null 
                            ? 'SAVE ${_type.name.toUpperCase()} (Ctrl+A)' 
                            : 'UPDATE ${_type.name.toUpperCase()} (Ctrl+A)', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  String _getPartyLabel() {
    switch (_type) {
      case VoucherType.sales:
      case VoucherType.quotation:
      case VoucherType.proforma:
        return 'Customer / Party A/c Name';
      case VoucherType.purchase:
        return 'Supplier / Party A/c Name';
      default:
        return 'Particulars';
    }
  }

  Color _getTypeColor() {
    switch (_type) {
      case VoucherType.sales: return Colors.blue.shade800;
      case VoucherType.purchase: return Colors.orange.shade800;
      case VoucherType.quotation: return Colors.teal.shade700;
      case VoucherType.proforma: return Colors.indigo.shade700;
      case VoucherType.payment: return Colors.red.shade700;
      case VoucherType.receipt: return Colors.green.shade700;
      default: return Theme.of(context).primaryColor;
    }
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

class ItemRowControllers {
  final TextEditingController descController;
  final TextEditingController hsnController;
  final TextEditingController snController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final FocusNode descFocusNode = FocusNode();
  final FocusNode hsnFocusNode = FocusNode();
  final FocusNode snFocusNode = FocusNode();
  final FocusNode qtyFocusNode = FocusNode();
  final FocusNode rateFocusNode = FocusNode();

  ItemRowControllers({String desc = '', String hsn = '', String sn = '', String qty = '', String rate = ''})
    : descController = TextEditingController(text: desc),
      hsnController = TextEditingController(text: hsn),
      snController = TextEditingController(text: sn),
      qtyController = TextEditingController(text: qty),
      rateController = TextEditingController(text: rate);

  double get totalAmount {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final rate = double.tryParse(rateController.text) ?? 0;
    return qty * rate;
  }

  void dispose() {
    descController.dispose();
    hsnController.dispose();
    snController.dispose();
    qtyController.dispose();
    rateController.dispose();
    descFocusNode.dispose();
    hsnFocusNode.dispose();
    snFocusNode.dispose();
    qtyFocusNode.dispose();
    rateFocusNode.dispose();
  }
}
