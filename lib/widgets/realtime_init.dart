import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// On the very first frame after sign-in:
///   * push the trainer's profile into the local UserDirectory + the
///     optional relay, and
///   * trigger a one-shot roster refresh so any member who onboarded on
///     another device appears immediately.
///
/// No timer-driven polling — the screens themselves drive refresh via
/// pull-to-refresh and on-action reloads.
class RealtimeInit extends ConsumerStatefulWidget {
  const RealtimeInit({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RealtimeInit> createState() => _RealtimeInitState();
}

class _RealtimeInitState extends ConsumerState<RealtimeInit> {
  String? _bootedFor;

  void _boot(String userId) {
    _bootedFor = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authServiceProvider).syncSelf();
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(userDirectoryProvider).upsert(user);
      }
      await ref.read(userDirectoryProvider).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null && user.id != _bootedFor) {
      _boot(user.id);
    }
    return widget.child;
  }
}
