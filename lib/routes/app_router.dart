import 'package:go_router/go_router.dart';
import '../pages/index.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/listing',
      builder: (context, state) => const JewelleryListingPage(),
    ),
    GoRoute(
      path: '/details',
      builder: (context, state) {
        final id = state.extra as int?;
        return id != null ? DetailsPage(jeweleryId: id) : const HomePage();
      },
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UsersPage(),
    ),
    GoRoute(
      path: '/user-details',
      builder: (context, state) {
        final id = state.extra as int?;
        return id != null ? UserDetailsPage(userId: id) : const UsersPage();
      },
    ),
    GoRoute(
      path: '/add-user',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final mode = args?['mode'] as String? ?? 'add';
        final id = args?['id'] as int?;
        return UserFormPage(mode: mode, userId: id);
      },
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final mode = args?['mode'] as String? ?? 'add';
        final id = args?['id'] as int?;
        return ProductFormPage(mode: mode, productId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/brands',
      builder: (context, state) => const BrandManagePage(),
    ),
    GoRoute(
      path: '/jewellery-types',
      builder: (context, state) => const JewelleryTypeManagePage(),
    ),
    GoRoute(
      path: '/photo-viewer',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final imagePaths = args?['imagePaths'] as List<String>? ?? [];
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        return PhotoViewerPage(imagePaths: imagePaths, initialIndex: initialIndex);
      },
    ),
  ],
);
