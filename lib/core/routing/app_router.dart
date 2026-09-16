import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/touchpad/presentation/touchpad_screen.dart';
import '../../features/keyboard/presentation/keyboard_screen.dart';
import '../../features/clipboard/presentation/clipboard_screen.dart';
import '../../features/file_transfer/presentation/file_transfer_screen.dart';
import '../../features/presentation/presentation/presentation_screen.dart';
import '../../features/pairing/presentation/qr_scanner_screen.dart';
import '../../features/companion/presentation/windows_companion_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Platform.isWindows ? '/windows-companion' : '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/devices',
              builder: (context, state) => const DevicesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (context, state) => const ActivityScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/touchpad',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TouchpadScreen(),
    ),
    GoRoute(
      path: '/keyboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const KeyboardScreen(),
    ),
    GoRoute(
      path: '/files',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FileTransferScreen(),
    ),
    GoRoute(
      path: '/clipboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ClipboardScreen(),
    ),
    GoRoute(
      path: '/presentation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PresentationScreen(),
    ),
    GoRoute(
      path: '/qr-scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/windows-companion',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WindowsCompanionScreen(),
    ),
  ],
);
