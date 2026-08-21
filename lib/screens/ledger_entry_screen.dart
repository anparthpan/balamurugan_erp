import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class LedgerEntryScreen extends StatefulWidget {
  final int? index;
  final Master? master;
  final VoidCallback? onActionDone;
  const LedgerEntryScreen({super.key, this.index, this.master, this.onActionDone});
  @override
  State<LedgerEntryScreen> createState() => _LedgerEntryScreenState();
}

class _LedgerEntryScreenState extends State<LedgerEntryScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  String _group = 'Customers';
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.master != null) {
      _nameController.text = widget.master!.name;
      _addressController.text = widget.master!.address;
      _phoneController.text = widget.master!.phone;
      _gstinController.text = widget.master!.gstin;
      _group = widget.master!.group;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final data = context.read<BalamuruganData>();
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Name')));
      return;
    }
    final newMaster = Master(
      name: _nameController.text.trim(),
      group: _group,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      gstin: _gstinController.text.trim(),
    );
    try {
      if (widget.index == null) {
        data.addLedger(newMaster);
      } else {
        data.updateLedger(widget.index!, newMaster);
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
            title: Text(widget.index == null ? 'LEDGER CREATION' : 'ALTER LEDGER'),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            automaticallyImplyLeading: false,
            actions: [
              if (widget.index != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    context.read<BalamuruganData>().deleteLedger(widget.index!);
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
                            const Text('LEDGER DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              initialValue: _group,
                              decoration: InputDecoration(
                                labelText: 'Account Type',
                                prefixIcon: const Icon(Icons.category_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: [
                                'Customers',
                                'Suppliers',
                                'Bank Accounts',
                                'Expenses',
                                'Other Income',
                                'Cash',
                                'Others'
                              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _group = v!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CONTACT INFORMATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _addressController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone / Contact',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            if (context.read<BalamuruganData>().currentCompany.isGstEnabled) ...[
                              const SizedBox(height: 20),
                              TextField(
                                controller: _gstinController,
                                decoration: InputDecoration(
                                  labelText: 'GSTIN',
                                  prefixIcon: const Icon(Icons.description_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
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
