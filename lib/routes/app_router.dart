import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/index.dart';
import '../screens/splash_screen.dart';

// ── Transition helpers ────────────────────────────────────────────────────────

/// Fade — used for sibling tab switches (go()).
CustomTransitionPage<void> _fadePage(
  LocalKey key,
  Widget child, {
  Duration duration = const Duration(milliseconds: 220),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Slide-up + fade — used for push drill-downs (details, forms, sheets).
CustomTransitionPage<void> _slidePage(
  LocalKey key,
  Widget child, {
  Duration duration = const Duration(milliseconds: 280),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

// ── Router ───────────────────────────────────────────────────────────────────

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Splash ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadePage(
        state.pageKey,
        const SplashScreen(),
        duration: const Duration(milliseconds: 600),
      ),
    ),

    // ── Tab-level routes (fade) ───────────────────────────────────────────
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _fadePage(state.pageKey, const HomePage()),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) =>
          _fadePage(state.pageKey, const DashboardPage()),
    ),
    GoRoute(
      path: '/listing',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, String?>?;
        return _fadePage(
          state.pageKey,
          JewelleryListingPage(
            initialType: extra?['type'],
            initialOwnerId: extra?['owner'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _fadePage(state.pageKey, const SettingsPage()),
    ),

    // ── Push drill-down routes (slide-up + fade) ──────────────────────────
    GoRoute(
      path: '/details',
      pageBuilder: (context, state) {
        final id = state.extra as int?;
        return _slidePage(
          state.pageKey,
          id != null ? DetailsPage(jeweleryId: id) : const HomePage(),
        );
      },
    ),
    GoRoute(
      path: '/add-product',
      pageBuilder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final mode = args?['mode'] as String? ?? 'add';
        final id = args?['id'] as int?;
        return _slidePage(
          state.pageKey,
          ProductFormPage(mode: mode, productId: id),
        );
      },
    ),
    GoRoute(
      path: '/users',
      pageBuilder: (context, state) =>
          _slidePage(state.pageKey, const UsersPage()),
    ),
    GoRoute(
      path: '/user-details',
      pageBuilder: (context, state) {
        final id = state.extra as int?;
        return _slidePage(
          state.pageKey,
          id != null ? UserDetailsPage(userId: id) : const UsersPage(),
        );
      },
    ),
    GoRoute(
      path: '/add-user',
      pageBuilder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final mode = args?['mode'] as String? ?? 'add';
        final id = args?['id'] as int?;
        return _slidePage(
          state.pageKey,
          UserFormPage(mode: mode, userId: id),
        );
      },
    ),
    GoRoute(
      path: '/gold-history',
      pageBuilder: (context, state) {
        final shopName = state.extra as String?;
        return _slidePage(
          state.pageKey,
          shopName != null
              ? GoldPriceHistoryPage(shopName: shopName)
              : const HomePage(),
          duration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: '/brands',
      pageBuilder: (context, state) =>
          _slidePage(state.pageKey, const BrandManagePage()),
    ),
    GoRoute(
      path: '/jewellery-types',
      pageBuilder: (context, state) =>
          _slidePage(state.pageKey, const JewelleryTypeManagePage()),
    ),
    GoRoute(
      path: '/photo-viewer',
      pageBuilder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final imagePaths = args?['imagePaths'] as List<String>? ?? [];
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        return _slidePage(
          state.pageKey,
          PhotoViewerPage(imagePaths: imagePaths, initialIndex: initialIndex),
        );
      },
    ),
  ],
);
