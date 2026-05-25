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
    return Card(
      color: joinable ? Theme.of(context).colorScheme.primary : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              joinable ? Icons.videocam_rounded : Icons.event_rounded,
              color: joinable ? Colors.white : AppColors.subtle,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    joinable ? 'Member is ready' : 'Next session',
                    style: TextStyle(
                      color: joinable ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TimeFormat.dateAndTime(call.scheduledFor),
                    style: TextStyle(
                      color: joinable
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.subtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (joinable)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => context.go('/home/prejoin/${call.id}'),
                child: const Text('Start'),
              ),
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: joinable ? Colors.white : AppColors.subtle,
              ),
              onPressed: () => ref.read(callServiceProvider).markCompleted(call),
            ),
          ],
        ),
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
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => context.go('/home/requests'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.ink, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    const Text('Tap to review and approve',
                        style: TextStyle(color: AppColors.subtle, fontSize: 12)),
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
