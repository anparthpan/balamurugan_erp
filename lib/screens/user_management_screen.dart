import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';
import '../models.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    
    // SECURITY CHECK: Only Admin should access this screen
    if (data.currentUser?.role != UserRole.admin) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('ACCESS DENIED', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
              Text('Only administrators can manage user accounts.'),
            ],
          ),
        ),
      );
    }

    final users = data.currentData.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('USER MANAGEMENT'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddUserDialog(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('ADD NEW USER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUTHORIZED EMPLOYEES & ACCESS CONTROL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isAdmin = user.role == UserRole.admin;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isAdmin ? Colors.blue.shade50 : Colors.orange.shade50,
                        child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.badge, color: isAdmin ? Colors.blue : Colors.orange),
                      ),
                      title: Text(user.username.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isAdmin ? 'Administrator (Full Access)' : 'Staff Member (Limited Access)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.key, color: Colors.blue),
                            onPressed: () => _showResetPasswordDialog(context, user.username),
                            tooltip: 'Reset Password',
                          ),
                          if (user.username != 'admin')
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, user.username),
                              tooltip: 'Delete User',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final passController = TextEditingController();
    UserRole selectedRole = UserRole.staff;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ADD NEW EMPLOYEE'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.security)),
                items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
                onChanged: (v) => setDialogState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && passController.text.isNotEmpty) {
                  try {
                    context.read<BalamuruganData>().addUser(User(
                      username: nameController.text.trim(),
                      password: passController.text,
                      role: selectedRole,
                    ));
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('CREATE ACCOUNT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, String username) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('RESET PASSWORD FOR $username'),
        content: TextField(
          controller: passController,
          decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_reset)),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (passController.text.isNotEmpty) {
                context.read<BalamuruganData>().resetPassword(username, passController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
              }
            },
            child: const Text('UPDATE PASSWORD'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE USER?'),
        content: Text('Are you sure you want to remove access for $username?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('NO')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<BalamuruganData>().deleteUser(username);
              Navigator.pop(context);
            },
            child: const Text('YES, DELETE'),
          ),
        ],
      ),
    );
  }
}
