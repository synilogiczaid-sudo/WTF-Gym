import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'app.dart';

/// Default API host seed for the very first launch.
///
/// `localhost` works out of the box whenever the device has an active
/// `adb reverse tcp:8787 tcp:8787` tunnel — i.e. the standard USB-debug
/// flow used during development — so the laptop's roaming LAN IP never
/// matters. For Wi-Fi-only review on a fresh install, pass
/// `--dart-define=API_HOST=<laptop_ip>` at build time, or set the IP
/// from the in-app DevPanel (long-press the home greeting).
const _kDefaultLanHost = String.fromEnvironment(
  'API_HOST',
  defaultValue: 'localhost',
);

Future<void> main() async {
  await SharedBootstrap.ensureInitialized(defaultApiHost: _kDefaultLanHost);
  if (ApiConfig.readHostOverride() == null) {
    final cfg = await ApiConfig.resolve();
    await ApiConfig.persistHostOverride(cfg.host);
    AppLogger.I.i(LogTag.app, 'api host resolved', {'host': cfg.host});
  } else {
    AppLogger.I.i(LogTag.app, 'api host loaded', {'host': ApiConfig.readHostOverride()!});
  }
  runApp(const ProviderScope(child: TrainerApp()));
}
