import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstinController;
  late TextEditingController _upiController;
  late TextEditingController _bankNameController;
  late TextEditingController _accNoController;
  late TextEditingController _ifscController;
  late TextEditingController _beneficiaryController;
  late bool _isGstEnabled;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    final company = context.read<BalamuruganData>().currentCompany;
    _nameController = TextEditingController(text: company.name);
    _addressController = TextEditingController(text: company.address);
    _phoneController = TextEditingController(text: company.phone);
    _gstinController = TextEditingController(text: company.gstin);
    _upiController = TextEditingController(text: company.upiId);
    _bankNameController = TextEditingController(text: company.bankName);
    _accNoController = TextEditingController(text: company.accNo);
    _ifscController = TextEditingController(text: company.ifsc);
    _beneficiaryController = TextEditingController(text: company.beneficiaryName);
    _isGstEnabled = company.isGstEnabled;
    _logoBase64 = company.logoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _upiController.dispose();
    _bankNameController.dispose();
    _accNoController.dispose();
    _ifscController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _logoBase64 = base64Encode(result.files.single.bytes!);
      });
    }
  }

  void _save() {
    final data = context.read<BalamuruganData>();
    final updated = Company(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      gstin: _gstinController.text.trim(),
      upiId: _upiController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accNo: _accNoController.text.trim(),
      ifsc: _ifscController.text.trim(),
      beneficiaryName: _beneficiaryController.text.trim(),
      isGstEnabled: _isGstEnabled,
      logoBase64: _logoBase64,
    );
    data.updateCompanyInfo(updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company settings updated')));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();

    return Column(
      children: [
        AppBar(
          title: const Text('COMPANY SETTINGS'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('COMPANY LOGO'),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: _logoBase64 != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(base64Decode(_logoBase64!), fit: BoxFit.contain),
                            )
                          : Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _sectionHeader('LAN SERVER SETTINGS (TALLY GOLD MODEL)'),
                const SizedBox(height: 15),
                _buildNetworkSettings(data),
                const SizedBox(height: 30),
                _sectionHeader('GENERAL INFORMATION'),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController, 
                          decoration: InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: const Icon(Icons.business_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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
                            labelText: 'Phone',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _sectionHeader('BANKING & UPI DETAILS'),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _upiController, 
                          decoration: InputDecoration(
                            labelText: 'UPI ID (for Payment QR)',
                            prefixIcon: const Icon(Icons.qr_code_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: 'e.g. yourname@okaxis',
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _beneficiaryController, 
                          decoration: InputDecoration(
                            labelText: 'Account Beneficiary Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _bankNameController, 
                          decoration: InputDecoration(
                            labelText: 'Bank Name',
                            prefixIcon: const Icon(Icons.account_balance_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _accNoController, 
                                decoration: InputDecoration(
                                  labelText: 'Account Number',
                                  prefixIcon: const Icon(Icons.numbers),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: TextField(
                                controller: _ifscController, 
                                decoration: InputDecoration(
                                  labelText: 'IFSC Code',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _sectionHeader('TAXATION (GST)'),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _gstinController, 
                          decoration: InputDecoration(
                            labelText: 'GSTIN',
                            prefixIcon: const Icon(Icons.receipt_long_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Enable GST Billing', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Toggle between GST and Non-GST invoices', style: TextStyle(fontSize: 12)),
                          value: _isGstEnabled,
                          activeThumbColor: Theme.of(context).primaryColor,
                          onChanged: (v) => setState(() => _isGstEnabled = v),
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
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const Divider(height: 80),
                _sectionHeader('MULTI-COMPANY MANAGEMENT'),
                const SizedBox(height: 16),
                Column(
                  children: data.companies.asMap().entries.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.value.info.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: data.currentCompanyIndex == e.key
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        data.switchCompany(e.key);
                      },
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showAddCompanyDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('CREATE NEW COMPANY'),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSettings(BalamuruganData data) {
    final ipController = TextEditingController(text: data.serverIp);
    final portController = TextEditingController(text: data.serverPort);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Network Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Connect to a central server in your office LAN'),
              value: data.isNetworkMode,
              onChanged: (val) => data.updateNetworkSettings(enabled: val, ip: data.serverIp, port: data.serverPort),
            ),
            if (data.isNetworkMode) ...[
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(labelText: 'Server IP Address', hintText: 'e.g. 192.168.1.5'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: portController,
                      decoration: const InputDecoration(labelText: 'Port', hintText: '8090'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => data.updateNetworkSettings(enabled: true, ip: ipController.text, port: portController.text),
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE SERVER CONFIG'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2));
  }

  void _showAddCompanyDialog(BuildContext context) {
    final controller = TextEditingController();
    final data = context.read<BalamuruganData>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Company'),
        content: TextField(
          controller: controller, 
          decoration: InputDecoration(
            hintText: 'Enter Company Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              data.addCompany(Company(name: controller.text));
              Navigator.pop(context);
            }
          }, child: const Text('CREATE')),
        ],
      ),
    );
  }
}
