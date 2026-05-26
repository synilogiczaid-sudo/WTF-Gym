import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

/// "Next call" CTA mirroring the member-side banner. Filters out completed
/// requests so the Join button disappears the moment either side ends the
/// call (the screen-scoped poller picks the flip up within ~2s).
final _nextApprovedCallProvider = StreamProvider<CallRequest?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(callServiceProvider).watchAll().map((all) {
    final upcoming = all
        .where((r) =>
            r.trainerId == user.id &&
            r.status == CallRequestStatus.approved &&
            !r.isWindowExpired)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return upcoming.isEmpty ? null : upcoming.first;
  });
});

final _pendingRequestCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  return ref.watch(callServiceProvider).watchAll().map((all) => all
      .where((r) => r.trainerId == user.id && r.status == CallRequestStatus.pending)
      .length);
});

class TrainerHomeBanners extends ConsumerWidget {
  const TrainerHomeBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(_nextApprovedCallProvider).valueOrNull;
    final pending = ref.watch(_pendingRequestCountProvider).valueOrNull ?? 0;

    final widgets = <Widget>[];
    if (next != null) {
      widgets.add(_NextCallCard(call: next));
    }
    if (pending > 0) {
      widgets.add(_PendingRequestsCard(count: pending));
    }

    if (widgets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widgets.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          widgets[i],
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _NextCallCard extends ConsumerWidget {
  const _NextCallCard({required this.call});
  final CallRequest call;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinable = call.isJoinable;
    if (joinable) return _LiveCallBanner(call: call, ref: ref);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.event_rounded, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next session',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  TimeFormat.dateAndTime(call.scheduledFor),
                  style: const TextStyle(color: AppColors.subtle, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded, color: AppColors.subtle, size: 18),
            onPressed: () => ref.read(callServiceProvider).markCompleted(call),
          ),
        ],
      ),
    );
  }
}

class _LiveCallBanner extends StatelessWidget {
  const _LiveCallBanner({required this.call, required this.ref});
  final CallRequest call;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, AppColors.ink, 0.4)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _LivePulse(),
                    SizedBox(width: 6),
                    Text(
                      'Member is ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TimeFormat.dateAndTime(call.scheduledFor),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.go('/home/prejoin/${call.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            child: const Text('Start'),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.85), size: 18),
            onPressed: () => ref.read(callServiceProvider).markCompleted(call),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestsCard extends StatelessWidget {
  const _PendingRequestsCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 new request' : '$count new requests';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/home/requests'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Tap to review and approve',
                      style: TextStyle(color: AppColors.subtle, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4 + _c.value * 0.5),
                blurRadius: 6 + _c.value * 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
