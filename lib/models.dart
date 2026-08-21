
enum VoucherType { payment, receipt, sales, purchase, contra, journal, quotation, proforma }

class Company {
  String name;
  String address;
  String phone;
  String gstin;
  String upiId; // Added for QR code generation
  String bankName;
  String accNo;
  String ifsc;
  String beneficiaryName;
  bool isGstEnabled;
  String? logoBase64; 

  Company({
    required this.name,
    this.address = '',
    this.phone = '',
    this.gstin = '',
    this.upiId = '',
    this.bankName = '',
    this.accNo = '',
    this.ifsc = '',
    this.beneficiaryName = '',
    this.isGstEnabled = false,
    this.logoBase64,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'gstin': gstin,
    'upiId': upiId,
    'bankName': bankName,
    'accNo': accNo,
    'ifsc': ifsc,
    'beneficiaryName': beneficiaryName,
    'isGstEnabled': isGstEnabled,
    'logoBase64': logoBase64,
  };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    name: json['name'],
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    gstin: json['gstin'] ?? '',
    upiId: json['upiId'] ?? '',
    bankName: json['bankName'] ?? '',
    accNo: json['accNo'] ?? '',
    ifsc: json['ifsc'] ?? '',
    beneficiaryName: json['beneficiaryName'] ?? '',
    isGstEnabled: json['isGstEnabled'] ?? false,
    logoBase64: json['logoBase64'],
  );
}

class Master {
  String name;
  String group; // e.g., Sundry Debtors, Cash-in-hand
  String address;
  String phone;
  String gstin;
  Master({
    required this.name, 
    required this.group, 
    this.address = '', 
    this.phone = '',
    this.gstin = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'group': group,
    'address': address,
    'phone': phone,
    'gstin': gstin,
  };

  factory Master.fromJson(Map<String, dynamic> json) => Master(
    name: json['name'],
    group: json['group'],
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    gstin: json['gstin'] ?? '',
  );
}

class StockItem {
  String name;
  String barcode;
  String category; // Motherboard, RAM, etc.
  String brand; // Dell, HP, Samsung
  double openingBalance;
  double lowStockThreshold;
  
  StockItem({
    required this.name, 
    this.barcode = '', 
    this.category = 'General',
    this.brand = 'Generic',
    this.openingBalance = 0,
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'barcode': barcode,
    'category': category,
    'brand': brand,
    'openingBalance': openingBalance,
    'lowStockThreshold': lowStockThreshold,
  };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    name: json['name'],
    barcode: json['barcode'] ?? '',
    category: json['category'] ?? 'General',
    brand: json['brand'] ?? 'Generic',
    openingBalance: (json['openingBalance'] ?? 0).toDouble(),
    lowStockThreshold: (json['lowStockThreshold'] ?? 5).toDouble(),
  );
}

enum UserRole { admin, staff }

class User {
  final String username;
  final String password;
  final UserRole role;

  User({required this.username, required this.password, required this.role});

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'role': role.index,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'],
    password: json['password'],
    role: UserRole.values[json['role'] ?? 0],
  );
}

enum ActionType { create, update, delete }

class AuditLog {
  final String id;
  final String entityId; // Voucher ID or Ledger Name
  final String entityType; // 'Voucher' or 'Master'
  final ActionType action;
  final DateTime timestamp;
  final String details;
  final String? previousState; // JSON string of previous state for comparison

  AuditLog({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.action,
    required this.timestamp,
    this.details = '',
    this.previousState,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityId': entityId,
    'entityType': entityType,
    'action': action.index,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
    'previousState': previousState,
  };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'],
    entityId: json['entityId'],
    entityType: json['entityType'],
    action: ActionType.values[json['action']],
    timestamp: DateTime.parse(json['timestamp']),
    details: json['details'] ?? '',
    previousState: json['previousState'],
  );
}

class LineItem {
  String description;
  String hsnCode;
  String serialNumber;
  double quantity;
  double rate;
  String unit;
  double gstRate; // Added for future GST support

  LineItem({
    required this.description, 
    this.hsnCode = '',
    this.serialNumber = '',
    this.quantity = 0, 
    this.rate = 0, 
    this.unit = 'No',
    this.gstRate = 0,
  });

  double get amount => quantity * rate;
  double get gstAmount => amount * (gstRate / 100);
  double get totalWithGst => amount + gstAmount;

  Map<String, dynamic> toJson() => {
    'description': description,
    'hsnCode': hsnCode,
    'serialNumber': serialNumber,
    'quantity': quantity,
    'rate': rate,
    'unit': unit,
    'gstRate': gstRate,
  };

  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(
    description: json['description'],
    hsnCode: json['hsnCode'] ?? '',
    serialNumber: json['serialNumber'] ?? '',
    quantity: (json['quantity'] ?? 0).toDouble(),
    rate: (json['rate'] ?? 0).toDouble(),
    unit: json['unit'] ?? 'No',
    gstRate: (json['gstRate'] ?? 0).toDouble(),
  );
}

class Voucher {
  final String id;
  final DateTime date;
  final String ledgerName;
  final String? customerAddress;
  final String? customerPhone;
  final double amount;
  final VoucherType type;
  final String narration;
  final String salesPerson; // Added for commission tracking
  final List<LineItem> items;
  bool isPaid;

  Voucher({
    required this.id,
    required this.date,
    required this.ledgerName,
    this.customerAddress,
    this.customerPhone,
    required this.amount,
    required this.type,
    this.narration = '',
    this.salesPerson = '',
    this.items = const [],
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'ledgerName': ledgerName,
    'customerAddress': customerAddress,
    'customerPhone': customerPhone,
    'amount': amount,
    'type': type.index,
    'narration': narration,
    'salesPerson': salesPerson,
    'items': items.map((e) => e.toJson()).toList(),
    'isPaid': isPaid,
  };

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'],
    date: DateTime.parse(json['date']),
    ledgerName: json['ledgerName'],
    customerAddress: json['customerAddress'],
    customerPhone: json['customerPhone'],
    amount: (json['amount'] ?? 0).toDouble(),
    type: VoucherType.values[json['type']],
    narration: json['narration'] ?? '',
    salesPerson: json['salesPerson'] ?? '',
    items: (json['items'] as List?)?.map((e) => LineItem.fromJson(e)).toList() ?? [],
    isPaid: json['isPaid'] ?? false,
  );
}

enum ServiceStatus { received, diagnosing, waitingForParts, ready, delivered }

class ServiceJob {
  final String jobCode;
  final DateTime date;
  final String customerName;
  final String description;
  final String serialNumber;
  final String accessories; // Charger, Bag, etc.
  final String diagnosis; // Technical findings
  final String engineerName;
  double amountCharged;
  ServiceStatus status;
  bool isPaid;

  ServiceJob({
    required this.jobCode,
    required this.date,
    required this.customerName,
    required this.description,
    this.serialNumber = '',
    this.accessories = '',
    this.diagnosis = '',
    required this.engineerName,
    this.amountCharged = 0,
    this.status = ServiceStatus.received,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'jobCode': jobCode,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'description': description,
    'serialNumber': serialNumber,
    'accessories': accessories,
    'diagnosis': diagnosis,
    'engineerName': engineerName,
    'amountCharged': amountCharged,
    'status': status.index,
    'isPaid': isPaid,
  };

  factory ServiceJob.fromJson(Map<String, dynamic> json) => ServiceJob(
    jobCode: json['jobCode'],
    date: DateTime.parse(json['date']),
    customerName: json['customerName'],
    description: json['description'],
    serialNumber: json['serialNumber'] ?? '',
    accessories: json['accessories'] ?? '',
    diagnosis: json['diagnosis'] ?? '',
    engineerName: json['engineerName'],
    amountCharged: (json['amountCharged'] ?? 0).toDouble(),
    status: ServiceStatus.values[json['status'] ?? 0],
    isPaid: json['isPaid'] ?? false,
  );
}
