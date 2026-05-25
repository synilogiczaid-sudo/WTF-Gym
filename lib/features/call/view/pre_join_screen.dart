import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/call_viewmodel.dart';

class PreJoinScreen extends ConsumerStatefulWidget {
  const PreJoinScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<PreJoinScreen> createState() => _PreJoinScreenState();
}

class _PreJoinScreenState extends ConsumerState<PreJoinScreen> {
  bool _micOn = true;
  bool _camOn = true;
  bool _joining = false;

  Future<void> _join(CallRequest req, User user) async {
    if (req.status == CallRequestStatus.completed) {
      showErrorSnackbar(context, message: 'This call has already ended.');
      return;
    }
    if (req.roomId == null) {
      showErrorSnackbar(context, message: 'Room not provisioned — approve the request first.');
      return;
    }
    setState(() => _joining = true);
    try {
      await ref.read(callSessionViewModelProvider.notifier).join(
            roomId: req.roomId!,
            userId: user.id,
            userName: user.name,
            role: 'trainer',
          );
      if (!mounted) return;
      context.go('/home/call/${req.id}');
    } catch (e, st) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        message: "Couldn't join the call. Please check your connection and try again.",
        error: e,
        stackTrace: st,
        tag: LogTag.rtc,
        logMessage: 'join failed',
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = ref.watch(callRequestProvider(widget.requestId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to join? Check mic and camera.'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: req.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const FriendlyError(title: "Couldn't load call details"),
          data: (r) {
            if (r == null || user == null) {
              return const EmptyState(title: 'Call not found');
            }
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          Text(_camOn ? 'Camera preview' : 'Camera off',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Session with your member',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled for ${TimeFormat.dateAndTime(r.scheduledFor)}',
                    style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _Toggle(
                          icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                          label: _micOn ? 'Mic on' : 'Mic off',
                          on: _micOn,
                          onTap: () => setState(() => _micOn = !_micOn),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _Toggle(
                          icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          label: _camOn ? 'Camera on' : 'Camera off',
                          on: _camOn,
                          onTap: () => setState(() => _camOn = !_camOn),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Start call',
                    icon: Icons.video_call_rounded,
                    loading: _joining,
                    onPressed: () => _join(r, user),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, required this.on, required this.onTap});

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: on ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: on ? AppColors.divider : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: on ? AppColors.ink : AppColors.subtle),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
