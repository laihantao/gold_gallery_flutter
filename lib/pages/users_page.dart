import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];

  // Stored so dispose() can remove the listener without touching context.
  RouteInformationProvider? _routeInfoProvider;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setRefreshListener();
  }

  void _setRefreshListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _routeInfoProvider = GoRouter.of(context).routeInformationProvider;
      _routeInfoProvider!.addListener(_onRouteChanged);
    });
  }

  void _onRouteChanged() {
    _loadUsers();
  }

  @override
  void dispose() {
    // Remove listener using the stored reference — context is deactivated here.
    _routeInfoProvider?.removeListener(_onRouteChanged);
    super.dispose();
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
        title: 'Users',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.textHeading),
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
                    if (!mounted) return;
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
}
