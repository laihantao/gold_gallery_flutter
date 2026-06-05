import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setRefreshListener();
  }

  void _setRefreshListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(context).routeInformationProvider?.addListener(_onRouteChanged);
    });
  }

  void _onRouteChanged() {
    _loadUsers();
  }

  @override
  void dispose() {
    GoRouter.of(context).routeInformationProvider?.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _loadUsers() {
    setState(() {
      users = HiveService.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Scaffold(
      appBar: AppHeader(
        title: 'Users',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.textHeading),
            onPressed: () async {
              await GoRouter.of(context).push('/add-user');
              _loadUsers();
            },
          ),
        ],
      ),
      body: users.isEmpty
          ? Center(
              child: Text(
                'No users found',
                style: TextStyle(color: appTheme.textBody),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return GestureDetector(
                  onTap: () async {
                    await GoRouter.of(context).push(
                      '/user-details',
                      extra: user.id,
                    );
                    _loadUsers();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: appTheme.borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
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
                          const SizedBox(height: 8),
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
                );
              },
            ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      GoRouter.of(context).go('/');
    } else if (index == 1) {
      GoRouter.of(context).go('/listing');
    } else if (index == 2) {
      GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
    } else if (index == 4) {
      GoRouter.of(context).go('/settings');
    }
  }
    
  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }
}
