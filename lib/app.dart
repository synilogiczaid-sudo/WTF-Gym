import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'router.dart';
import 'widgets/realtime_init.dart';

class TrainerApp extends ConsumerWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(trainerRouterProvider);
    return RealtimeInit(
      child: MaterialApp.router(
        title: 'WTF Trainer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(AppFlavor.trainer),
        routerConfig: router,
      ),
    );
  }
}
