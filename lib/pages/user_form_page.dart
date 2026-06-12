import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';

class UserFormPage extends StatefulWidget {
  final String mode;
  final int? userId;

  const UserFormPage({
    super.key,
    required this.mode,
    this.userId,
  });

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _descriptionController;

  User? _existingUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.mode == 'edit' && widget.userId != null) {
      _existingUser = HiveService.getUser(widget.userId!);
      if (_existingUser != null) {
        _nameController.text = _existingUser!.name;
        if (_existingUser!.dateOfBirth != null) {
          _dobController.text = DateFormat('dd/MM/yyyy').format(_existingUser!.dateOfBirth!);
        }
        _descriptionController.text = _existingUser!.description ?? '';
      }
    }
  }

  void _saveUser() {
    if (_nameController.text.isEmpty) {
      _showValidationError('Name is required');
      return;
    }

    try {
      final now = DateTime.now();
      final dob = _dobController.text.isNotEmpty ? DateFormat('dd/MM/yyyy').parse(_dobController.text) : null;

      final user = User(
        id: _existingUser?.id ?? HiveService.getNextUserId(),
        name: _nameController.text,
        dateOfBirth: dob,
        description: _descriptionController.text,
        createdAt: _existingUser?.createdAt ?? now,
        updatedAt: now,
      );

      HiveService.saveUser(user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User saved successfully')),
      );
      if (mounted) {
        GoRouter.of(context).pop();
      }
    } catch (e) {
      _showValidationError('Error saving user: $e');
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      appBar: AppHeader(title: widget.mode == 'add' ? 'Add User' : 'Edit User'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormField('Name *', _nameController, appTheme),
            const SizedBox(height: 16),
            _buildFormField(
              'Date of Birth',
              _dobController,
              appTheme,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildFormField('Description', _descriptionController, appTheme, maxLines: 3),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save User',
              onPressed: _saveUser,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    AppTheme appTheme, {
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onTap: onTap,
          readOnly: onTap != null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.accentPrimary),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
          style: TextStyle(color: appTheme.textHeading),
        ),
      ],
    );
  }

}

// User Details Page
class UserDetailsPage extends StatefulWidget {
  final int userId;

  const UserDetailsPage({super.key, required this.userId});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = HiveService.getUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    if (user == null) {
      return Scaffold(
        appBar: AppHeader(title: 'User Details'),
        body: Center(
          child: Text('User not found', style: TextStyle(color: appTheme.textBody)),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeader(title: user!.name),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Name',
              value: user!.name,
              appTheme: appTheme,
            ),
            if (user!.dateOfBirth != null)
              _DetailRow(
                label: 'Date of Birth',
                value: '${user!.dateOfBirth!.day}/${user!.dateOfBirth!.month}/${user!.dateOfBirth!.year}',
                appTheme: appTheme,
              ),
            if (user!.description != null && user!.description!.isNotEmpty)
              _DetailRow(
                label: 'Description',
                value: user!.description!,
                appTheme: appTheme,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Edit',
                    onPressed: () {
                      GoRouter.of(context).push(
                        '/add-user',
                        extra: {'mode': 'edit', 'id': user!.id},
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GhostButton(
                    label: 'Delete',
                    onPressed: () {
                      _showDeleteConfirmation(context, appTheme);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppTheme appTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete User',
          style: TextStyle(color: appTheme.textHeading),
        ),
        content: Text(
          'Are you sure you want to delete this user?',
          style: TextStyle(color: appTheme.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: appTheme.accentSecondary)),
          ),
          TextButton(
            onPressed: () {
              final userName = user!.name;
              HiveService.deleteUser(user!.id);
              GoRouter.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User "$userName" deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme appTheme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: appTheme.textBody,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: appTheme.textHeading,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
