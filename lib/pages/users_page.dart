import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';

/// Users management page — accessed from Settings, not from the bottom nav.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    if (!mounted) return;
    setState(() {
      users = HiveService.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      appBar: AppHeader(
        title: 'Manage Users',
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: appTheme.textHeading),
            tooltip: 'Add user',
            onPressed: () async {
              await GoRouter.of(context).push('/add-user');
              if (!mounted) return;
              _loadUsers();
            },
          ),
        ],
      ),
      body: users.isEmpty
          ? Center(
              child: Text(
                'No users yet. Tap + to add one.',
                style: TextStyle(color: appTheme.textBody),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final initial =
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
                return GestureDetector(
                  onTap: () async {
                    await GoRouter.of(context).push(
                      '/user-details',
                      extra: user.id,
                    );
                    if (!mounted) return;
                    _loadUsers();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appTheme.borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: appTheme.accentPrimary
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: appTheme.accentSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  color: appTheme.textHeading,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (user.dateOfBirth != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'DOB: ${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}',
                                  style: TextStyle(
                                    color: appTheme.textBody,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_outlined,
                            color: appTheme.borderColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
