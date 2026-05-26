import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/requests_viewmodel.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync = ScreenSync(
        label: 'requests',
        tick: () => ref.read(callServiceProvider).refresh(),
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
    final pending = ref.watch(pendingRequestsProvider);
    final today = ref.watch(approvedTodayProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Call Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            const _SectionHeader(
              title: 'Pending',
              subtitle: 'Approve or decline so members can plan their day.',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            pending.when(
              loading: () => const _LoadingBlock(),
              error: (_, __) => const _InfoCard(
                icon: Icons.cloud_off_rounded,
                text: "Couldn't load requests right now.",
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _InfoCard(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'All caught up — no pending requests.',
                  );
                }
                return Column(children: list.map((r) => _PendingCard(req: r)).toList());
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
              title: 'Approved',
              subtitle: 'Upcoming calls you\'ve agreed to.',
              icon: Icons.event_available_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            today.when(
              loading: () => const _LoadingBlock(),
              error: (_, __) => const _InfoCard(
                icon: Icons.cloud_off_rounded,
                text: "Couldn't load approved calls.",
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _InfoCard(
                    icon: Icons.event_busy_outlined,
                    text: 'No approved calls yet.',
                  );
                }
                return Column(children: list.map((r) => _ApprovedCard(req: r)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.subtle, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: AppColors.subtle, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.subtle, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard({required this.req});
  final CallRequest req;

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(requestActionsProvider.notifier).approve(widget.req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved — ${TimeFormat.dateAndTime(widget.req.scheduledFor)}')),
      );
    } on ConflictError catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, message: e.message);
    } catch (e, st) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        message: "Couldn't approve the request. Please try again.",
        error: e,
        stackTrace: st,
        tag: LogTag.schedule,
        logMessage: 'approve failed',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(requestActionsProvider.notifier).decline(widget.req, reason.trim());
    } catch (e, st) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        message: "Couldn't decline the request. Please try again.",
        error: e,
        stackTrace: st,
        tag: LogTag.schedule,
        logMessage: 'decline failed',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _memberInitial(String memberId) {
    if (memberId.startsWith('member_')) {
      return memberId.substring(7).characters.first.toUpperCase();
    }
    return memberId.isNotEmpty ? memberId.characters.first.toUpperCase() : '?';
  }

  String _memberLabel(String memberId) {
    if (memberId == 'member_dk') return 'DK';
    if (memberId.startsWith('member_')) {
      return 'Member ${memberId.substring(7).toUpperCase()}';
    }
    return memberId;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.req;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.guruPrimary, Color(0xFF4F8DEB)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _memberInitial(r.memberId),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _memberLabel(r.memberId),
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 11, color: AppColors.subtle),
                        const SizedBox(width: 4),
                        Text(
                          TimeFormat.dateAndTime(r.scheduledFor),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Text(
              'Requested ${TimeFormat.relative(r.requestedAt)}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.subtle),
            ),
          ),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.dividerSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: AppColors.muted, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.note,
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Decline',
                  icon: Icons.close_rounded,
                  onPressed: _busy ? null : _decline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  loading: _busy,
                  onPressed: _approve,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline reason'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Share a short note so DK knows what to try next.',
            style: TextStyle(color: AppColors.subtle, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Slot conflicts with another session',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}

class _ApprovedCard extends StatelessWidget {
  const _ApprovedCard({required this.req});
  final CallRequest req;

  @override
  Widget build(BuildContext context) {
    final joinable = req.isJoinable;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: joinable ? AppColors.success.withValues(alpha: 0.35) : AppColors.divider,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (joinable ? AppColors.success : AppColors.subtle)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: joinable ? AppColors.success : AppColors.subtle,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimeFormat.dateAndTime(req.scheduledFor),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  req.note.isEmpty ? 'No note' : req.note,
                  style: const TextStyle(fontSize: 12, color: AppColors.subtle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (joinable)
            FilledButton(
              onPressed: () => context.go('/home/prejoin/${req.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
              ),
              child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
