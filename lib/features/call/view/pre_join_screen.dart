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
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Ready to start?'),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PreviewTile(
                    camOn: _camOn,
                    micOn: _micOn,
                    name: user.name,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Session with your member',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 14, color: AppColors.subtle),
                      const SizedBox(width: 6),
                      Text(
                        TimeFormat.dateAndTime(r.scheduledFor),
                        style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                      ),
                    ],
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

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.camOn,
    required this.micOn,
    required this.name,
  });

  final bool camOn;
  final bool micOn;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F2A3D),
            AppColors.ink.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33101828),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    camOn ? Icons.person_rounded : Icons.videocam_off_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  camOn ? 'Camera preview' : 'Camera off',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: on ? Colors.white : AppColors.ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: on ? AppColors.divider : Colors.transparent,
            ),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x0A101828),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: on ? AppColors.ink : AppColors.muted, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
