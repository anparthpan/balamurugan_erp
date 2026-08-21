import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class StockItemEntryScreen extends StatefulWidget {
  final int? index;
  final StockItem? item;
  final VoidCallback? onActionDone;
  const StockItemEntryScreen({super.key, this.index, this.item, this.onActionDone});
  @override
  State<StockItemEntryScreen> createState() => _StockItemEntryScreenState();
}

class _StockItemEntryScreenState extends State<StockItemEntryScreen> {
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _openingController = TextEditingController();
  final _thresholdController = TextEditingController();
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _barcodeController.text = widget.item!.barcode;
      _categoryController.text = widget.item!.category;
      _brandController.text = widget.item!.brand;
      _openingController.text = widget.item!.openingBalance.toString();
      _thresholdController.text = widget.item!.lowStockThreshold.toString();
    } else {
      _openingController.text = '0';
      _thresholdController.text = '5';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _openingController.dispose();
    _thresholdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final data = context.read<BalamuruganData>();
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an Item Name')));
      return;
    }
    final newItem = StockItem(
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      category: _categoryController.text.trim(),
      brand: _brandController.text.trim(),
      openingBalance: double.tryParse(_openingController.text) ?? 0,
      lowStockThreshold: double.tryParse(_thresholdController.text) ?? 5,
    );
    try {
      if (widget.index == null) {
        data.addStockItem(newItem);
      } else {
        data.updateStockItem(widget.index!, newItem);
      }
      widget.onActionDone?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
          _save();
        }
      },
      child: Column(
        children: [
          AppBar(
            title: Text(widget.index == null ? 'STOCK ITEM CREATION' : 'ALTER STOCK ITEM'),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            automaticallyImplyLeading: false,
            actions: [
              if (widget.index != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    context.read<BalamuruganData>().deleteStockItem(widget.index!);
                    widget.onActionDone?.call();
                  },
                ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ITEM DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Item Name',
                                prefixIcon: const Icon(Icons.inventory_2_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barcode (Optional)',
                                prefixIcon: const Icon(Icons.qr_code_scanner),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _categoryController,
                                    decoration: InputDecoration(
                                      labelText: 'Category',
                                      prefixIcon: const Icon(Icons.category_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: TextField(
                                    controller: _brandController,
                                    decoration: InputDecoration(
                                      labelText: 'Brand',
                                      prefixIcon: const Icon(Icons.branding_watermark_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _openingController,
                                    decoration: InputDecoration(
                                      labelText: 'Opening Balance',
                                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: TextField(
                                    controller: _thresholdController,
                                    decoration: InputDecoration(
                                      labelText: 'Low Stock Alert Qty',
                                      prefixIcon: const Icon(Icons.notification_important_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle),
                        label: Text(widget.index == null ? 'ACCEPT (Ctrl+A)' : 'UPDATE (Ctrl+A)',
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
}
