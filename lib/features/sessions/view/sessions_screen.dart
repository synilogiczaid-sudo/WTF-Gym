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
      backgroundColor: AppColors.bgSoft,
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
            _FilterBar(
              filter: filter,
              onSelected: (f) =>
                  ref.read(sessionsFilterProvider.notifier).state = f,
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
                      subtitle:
                          'Completed calls will appear here with their duration and ratings.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.read(logServiceProvider).refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _SessionTile(log: list[i]),
                    ),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onSelected});

  final SessionsFilter filter;
  final ValueChanged<SessionsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          children: SessionsFilter.values.map((f) {
            final selected = f == filter;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x14101828),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? primary : AppColors.subtle,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
    final completed = log.completed;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: () => _openDetail(context, log),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08101828),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (completed ? AppColors.success : AppColors.subtle)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  completed ? Icons.task_alt_rounded : Icons.videocam_rounded,
                  color: completed ? AppColors.success : AppColors.subtle,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeFormat.dateAndTime(log.startedAt),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.subtle),
                        const SizedBox(width: 4),
                        Text(
                          TimeFormat.duration(Duration(seconds: log.durationSec)),
                          style: const TextStyle(fontSize: 12, color: AppColors.subtle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (log.rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                      const SizedBox(width: 3),
                      Text('${log.rating}',
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, SessionLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(TimeFormat.dateAndTime(log.startedAt),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Duration • ${TimeFormat.duration(Duration(seconds: log.durationSec))}',
                        style: const TextStyle(color: AppColors.subtle, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (log.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                        const SizedBox(width: 3),
                        Text('${log.rating}',
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _DetailLabel('Member notes'),
            _DetailBubble(text: log.memberNotes),
            const SizedBox(height: AppSpacing.md),
            const _DetailLabel('Your notes'),
            _DetailBubble(text: log.trainerNotes),
          ],
        ),
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.subtle,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      );
}

class _DetailBubble extends StatelessWidget {
  const _DetailBubble({required this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    final hasText = text?.trim().isNotEmpty ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.dividerSoft),
      ),
      child: Text(
        hasText ? text! : '—',
        style: TextStyle(
          fontSize: 13.5,
          color: hasText ? AppColors.inkSoft : AppColors.muted,
          fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
          height: 1.45,
        ),
      ),
    );
  }
}
