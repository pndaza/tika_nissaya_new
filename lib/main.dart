import 'dart:io' show Platform, Process;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'client/shared_pref_client.dart';
import 'utils/window_config.dart';

final myLogger = Logger();

const _defaultSize = Size(800, 600);
const _minSize = Size(400, 300);
const _scheme = 'tikanissaya';

Future<void> main() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode && Platform.isWindows) {
    _registerUrlScheme();
  }

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    final windowConfig = await WindowConfig.loadWindowConfig();
    await windowManager.ensureInitialized();

    final double? left = windowConfig?['left'];
    final double? top = windowConfig?['top'];
    final double? width = windowConfig?['width'];
    final double? height = windowConfig?['height'];
    final isMaximized = windowConfig?['isMaximized'] == 1.0;

    final hasPosition = left != null && top != null;
    final hasSize = width != null && height != null;

    final windowSize = hasSize
        ? Size(width, height)
        : _defaultSize;

    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      center: !hasPosition,
      minimumSize: _minSize,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (isMaximized) {
        await windowManager.maximize();
      } else if (left != null && top != null && width != null && height != null) {
        final restored = Rect.fromLTWH(left, top, width, height);
        if (_isWindowOnScreen(restored)) {
          await windowManager.setBounds(restored);
        }
      }

      await windowManager.show();
      await windowManager.focus();
    });
  }

  await SharedPreferenceClient.init();

  runApp(const ProviderScope(child: MyApp()));
}

bool _isWindowOnScreen(Rect bounds) {
  for (final display in PlatformDispatcher.instance.displays) {
    final screen = Rect.fromLTWH(
      0,
      0,
      display.size.width,
      display.size.height,
    );
    if (bounds.overlaps(screen)) return true;
  }
  return bounds.left >= 0 && bounds.top >= 0;
}

void _registerUrlScheme() {
  final exe = Platform.resolvedExecutable;
  Process.runSync('reg', [
    'add',
    'HKCU\\Software\\Classes\\$_scheme',
    '/v', 'URL Protocol', '/d', '', '/f',
  ]);
  Process.runSync('reg', [
    'add',
    'HKCU\\Software\\Classes\\$_scheme\\shell\\open\\command',
    '/ve', '/d', '"$exe" "%1"', '/f',
  ]);
}
