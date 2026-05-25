import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'app.dart';

/// Last-known LAN IP of the laptop running `token_server`. Acts as a
/// best-effort seed for the very first launch; overridable at build time
/// via `--dart-define=API_HOST=...`.
const _kDefaultLanHost = String.fromEnvironment(
  'API_HOST',
  defaultValue: '10.28.39.79',
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
