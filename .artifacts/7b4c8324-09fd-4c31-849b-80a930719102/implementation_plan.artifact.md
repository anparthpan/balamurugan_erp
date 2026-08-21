# Implementation Plan - ERP Final Polish & Enterprise Features

This plan aims to complete the missing deliverables: Professional Login, Multi-user support, Role-based access, and Barcode support.

## Deliverables Checklist & Status
- [x] Modern Dashboard
- [x] GST Billing
- [x] Computer Sales Billing
- [x] Service Center Management
- [x] Inventory Management
- [x] Purchase Management
- [x] Customer Management
- [x] PDF Invoice Generation
- [x] Reports and Analytics
- [x] Backup & Restore
- [ ] **Professional Login Screen** (Pending)
- [ ] **Barcode Support** (Pending)
- [ ] **Multi-user support** (Pending)
- [ ] **Secure Role-based access** (Pending)

## Proposed Changes

### 1. Data Models (`lib/models.dart`)
- **[NEW] User**: Model for login (`username`, `password`, `role`).
- **[NEW] UserRole**: Enum (`admin`, `staff`).
- **[MODIFY] StockItem**: Add `barcode` field.

### 2. Business Logic (`lib/balamurugan_data.dart`)
- Add `List<User>` and `currentUser` session handling.
- Update `addStockItem` and `updateStockItem` to handle barcodes.
- Add authentication method (`login(username, password)`).

### 3. UI - Login (`lib/screens/login_screen.dart`)
- **[NEW]** Professional, secure login screen with branding.

### 4. UI - Enterprise Features
- **[MODIFY] StockItemEntryScreen**: Add Barcode field.
- **[MODIFY] VoucherEntryScreen**: Enhance item search to detect barcode scans.
- **[MODIFY] HomeScreen**: Implement session check (show Login if not authenticated) and Role-based menu visibility.

## Verification Plan
1.  **Login**: Verify that only valid users can enter. Verify "Admin" can see all menus while "Staff" is restricted (e.g., no Audit Log).
2.  **Barcode**: Add an item with barcode "12345". In Voucher Entry, type "12345" and verify the item is auto-selected.
3.  **Role Access**: Log in as Staff and check if "Edit Log" and "Data Backup" are hidden.
