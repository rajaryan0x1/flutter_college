import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A2B4A),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF1A2B4A),
          secondary: const Color(0xFFFF6B6B),
          surface: const Color(0xFFF7F9FC),
        ),
        fontFamily: 'Georgia',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A2B4A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const UserScreen(),
    );
  }
}

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final String baseUrl = "http://localhost:8080/api/users";
  List users = [];
  bool isLoading = false;

  // ── API Methods ──────────────────────────────────────────────────────────

  Future<void> addUser() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
        }),
      );
      _showSnack("User added successfully", isError: false);
      await fetchUsers();
    } catch (_) {
      _showSnack("Failed to add user");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));
      setState(() => users = jsonDecode(response.body));
    } catch (_) {
      _showSnack("Failed to load users");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUser(int id, String name, String email) async {
    setState(() => isLoading = true);
    try {
      await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email}),
      );
      _showSnack("User updated", isError: false);
      await fetchUsers();
    } catch (_) {
      _showSnack("Failed to update user");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await http.delete(Uri.parse("$baseUrl/$id"));
      _showSnack("User deleted", isError: false);
      await fetchUsers();
    } catch (_) {
      _showSnack("Failed to delete user");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Georgia')),
        backgroundColor: isError ? const Color(0xFFFF6B6B) : const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAddUserSheet() {
    nameController.clear();
    emailController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddUserSheet(
        nameController: nameController,
        emailController: emailController,
        onAdd: () {
          Navigator.pop(context);
          addUser();
        },
      ),
    );
  }

  void _showEditDialog(Map user) {
    final editName = TextEditingController(text: user['name']);
    final editEmail = TextEditingController(text: user['email']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit User',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2B4A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editName,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2B4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              updateUser(user['id'], editName.text, editEmail.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete User',
          style: TextStyle(fontFamily: 'Georgia', color: Color(0xFF1A2B4A)),
        ),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteUser(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Manager',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: fetchUsers,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserSheet,
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add User',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading && users.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A2B4A)),
            )
          : users.isEmpty
              ? _EmptyState(onAdd: _showAddUserSheet)
              : RefreshIndicator(
                  onRefresh: fetchUsers,
                  color: const Color(0xFF1A2B4A),
                  child: Column(
                    children: [
                      // Stats bar
                      Container(
                        color: const Color(0xFF1A2B4A),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          children: [
                            _StatChip(
                              icon: Icons.people_rounded,
                              label: '${users.length} users',
                            ),
                          ],
                        ),
                      ),

                      // User list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _UserCard(
                              user: user,
                              index: index,
                              onEdit: () => _showEditDialog(user),
                              onDelete: () => _confirmDelete(user['id'], user['name']),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final Map user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  String get _initials {
    final parts = (user['name'] as String).trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF1A2B4A),
      const Color(0xFFFF6B6B),
      const Color(0xFF2ECC71),
      const Color(0xFF9B59B6),
      const Color(0xFFF39C12),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _avatarColor,
          radius: 24,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Georgia',
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          user['name'],
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A2B4A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  user['email'],
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: const Color(0xFF1A2B4A),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, size: 20),
              color: const Color(0xFFFF6B6B),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _AddUserSheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onAdd;

  const _AddUserSheet({
    required this.nameController,
    required this.emailController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add New User',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B4A),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add User',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B4A).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: Color(0xFF1A2B4A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No users yet',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B4A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add your first user',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text(
              'Add First User',
              style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}