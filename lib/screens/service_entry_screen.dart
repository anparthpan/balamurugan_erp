import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';
import 'service_pdf_screen.dart';

class ServiceEntryScreen extends StatefulWidget {
  final ServiceJob? job;
  final VoidCallback? onActionDone;
  const ServiceEntryScreen({super.key, this.job, this.onActionDone});

  @override
  State<ServiceEntryScreen> createState() => _ServiceEntryScreenState();
}

class _ServiceEntryScreenState extends State<ServiceEntryScreen> {
  late TextEditingController _customerController;
  late TextEditingController _descController;
  late TextEditingController _snController;
  late TextEditingController _accController;
  late TextEditingController _diagController;
  late TextEditingController _engineerController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late ServiceStatus _status;
  late bool _isPaid;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _customerController = TextEditingController(text: widget.job?.customerName ?? '');
    _descController = TextEditingController(text: widget.job?.description ?? '');
    _snController = TextEditingController(text: widget.job?.serialNumber ?? '');
    _accController = TextEditingController(text: widget.job?.accessories ?? '');
    _diagController = TextEditingController(text: widget.job?.diagnosis ?? '');
    _engineerController = TextEditingController(text: widget.job?.engineerName ?? '');
    _amountController = TextEditingController(text: widget.job?.amountCharged.toString() ?? '0');
    _selectedDate = widget.job?.date ?? DateTime.now();
    _status = widget.job?.status ?? ServiceStatus.received;
    _isPaid = widget.job?.isPaid ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _descController.dispose();
    _snController.dispose();
    _accController.dispose();
    _diagController.dispose();
    _engineerController.dispose();
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _save() {
    if (_customerController.text.isEmpty) return;

    final data = context.read<BalamuruganData>();
    final job = ServiceJob(
      jobCode: widget.job?.jobCode ?? data.getNextServiceJobNumber(),
      date: _selectedDate,
      customerName: _customerController.text,
      description: _descController.text,
      serialNumber: _snController.text,
      accessories: _accController.text,
      diagnosis: _diagController.text,
      engineerName: _engineerController.text,
      amountCharged: double.tryParse(_amountController.text) ?? 0,
      status: _status,
      isPaid: _isPaid,
    );

    if (widget.job == null) {
      data.addServiceJob(job);
    } else {
      data.updateServiceJob(job);
    }
    widget.onActionDone?.call();
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
          title: Text(widget.job == null ? 'SERVICE JOB ENTRY' : 'UPDATE SERVICE JOB'),
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          elevation: 2,
          automaticallyImplyLeading: false,
          actions: [
            if (widget.job != null) ...[
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServicePdfScreen(job: widget.job!))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  context.read<BalamuruganData>().deleteServiceJob(widget.job!.jobCode);
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER & DEVICE DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 20),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Job Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            subtitle: Text(DateFormat('dd-MMM-yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectDate,
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          Autocomplete<String>(
                            optionsBuilder: (v) => context.read<BalamuruganData>().ledgers.map((l) => l.name).where((n) => n.toLowerCase().contains(v.text.toLowerCase())),
                            onSelected: (v) => _customerController.text = v,
                            fieldViewBuilder: (context, controller, focus, onFieldSubmitted) {
                              if (controller.text.isEmpty && _customerController.text.isNotEmpty) {
                                controller.text = _customerController.text;
                              }
                              return TextField(
                                controller: controller,
                                focusNode: focus,
                                onChanged: (v) => _customerController.text = v,
                                decoration: InputDecoration(
                                  labelText: 'Customer Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _snController,
                            decoration: InputDecoration(
                              labelText: 'Device Serial Number',
                              prefixIcon: const Icon(Icons.qr_code_scanner),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _accController,
                            decoration: InputDecoration(
                              labelText: 'Accessories Received (Charger, Bag, etc.)',
                              prefixIcon: const Icon(Icons.shopping_bag_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _descController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Customer Complaint',
                              prefixIcon: const Icon(Icons.report_problem_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                          const Text('TECHNICAL DIAGNOSIS & BILLING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _engineerController,
                            decoration: InputDecoration(
                              labelText: 'Assigned Engineer',
                              prefixIcon: const Icon(Icons.engineering_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _diagController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Technician Findings / Diagnosis',
                              prefixIcon: const Icon(Icons.biotech_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount Charged',
                              prefixIcon: const Icon(Icons.currency_rupee),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<ServiceStatus>(
                            initialValue: _status,
                            decoration: InputDecoration(
                              labelText: 'Job Status',
                              prefixIcon: const Icon(Icons.info_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ServiceStatus.values.map((s) => DropdownMenuItem(
                              value: s, 
                              child: Text(s.name.toUpperCase().replaceAll('FOR', ' FOR ')),
                            )).toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            title: const Text('Payment: Received'),
                            value: _isPaid,
                            onChanged: (v) => setState(() => _isPaid = v),
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
                      label: Text(widget.job == null ? 'ACCEPT' : 'UPDATE',
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
