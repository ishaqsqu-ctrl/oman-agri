import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/motion.dart';
import 'package:oman_agri/features/admin/admin_screen.dart';
import 'package:oman_agri/features/crops/ui/crop_detail_screen.dart';
import 'package:oman_agri/features/crops/ui/crops_list_screen.dart';
import 'package:oman_agri/features/settings/settings_screen.dart';
import 'package:oman_agri/features/shell/coming_soon_screen.dart';
import 'package:oman_agri/features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (c, s) => const CropsListScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/map',
                  builder: (c, s) => const ComingSoonScreen('map')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/calendar',
                  builder: (c, s) => const ComingSoonScreen('calendar')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/farm',
                  builder: (c, s) => const ComingSoonScreen('farm')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/store',
                  builder: (c, s) => const ComingSoonScreen('store')),
            ]),
          ],
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootKey,
          builder: (c, s) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/crops/:id',
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              fadeScalePage(s, CropDetailScreen(cropId: s.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/admin',
          parentNavigatorKey: _rootKey,
          builder: (c, s) => const AdminScreen(),
        ),
      ],
    );

/// Shared router for the running app.
final appRouter = buildRouter();
