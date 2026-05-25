import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/sessions_viewmodel.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync = ScreenSync(
        label: 'sessions',
        tick: () => ref.read(logServiceProvider).refresh(),
      )..start();
    });
  }

  @override
  void dispose() {
    _sync?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(sessionsFilterProvider);
    final logs = ref.watch(trainerSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Wrap(
                spacing: 8,
                children: SessionsFilter.values.map((f) {
                  return ChoiceChip(
                    label: Text(f.label),
                    selected: f == filter,
                    onSelected: (_) => ref.read(sessionsFilterProvider.notifier).state = f,
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: logs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const FriendlyError(title: "Couldn't load sessions"),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.timer_off_outlined,
                      title: 'No sessions yet',
                      subtitle: 'Completed calls will appear here with their duration and ratings.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _SessionTile(log: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.log});
  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetail(context, log),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                log.completed ? Icons.task_alt_rounded : Icons.videocam_rounded,
                color: log.completed ? AppColors.success : AppColors.subtle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TimeFormat.dateAndTime(log.startedAt),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(TimeFormat.duration(Duration(seconds: log.durationSec)),
                      style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
                ],
              ),
            ),
            if (log.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 2),
                  Text('${log.rating}',
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, SessionLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TimeFormat.dateAndTime(log.startedAt),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Duration • ${TimeFormat.duration(Duration(seconds: log.durationSec))}',
              style: const TextStyle(color: AppColors.subtle, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            const _Label('Member notes'),
            Text(log.memberNotes?.trim().isNotEmpty == true ? log.memberNotes! : '—'),
            const SizedBox(height: AppSpacing.md),
            const _Label('Your notes'),
            Text(log.trainerNotes?.trim().isNotEmpty == true ? log.trainerNotes! : '—'),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.w600)),
      );
}
