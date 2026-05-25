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
      appBar: AppBar(
        title: const Text('Call Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Pending', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            pending.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _InfoCard("Couldn't load requests right now."),
              data: (list) {
                if (list.isEmpty) {
                  return const _InfoCard('No pending requests right now.');
                }
                return Column(children: list.map((r) => _PendingTile(req: r)).toList());
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text("Approved", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            today.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _InfoCard("Couldn't load approved calls."),
              data: (list) {
                if (list.isEmpty) {
                  return const _InfoCard('No approved calls yet.');
                }
                return Column(children: list.map((r) => _ApprovedTile(req: r)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(text, style: const TextStyle(color: AppColors.subtle)),
      ),
    );
  }
}

class _PendingTile extends ConsumerStatefulWidget {
  const _PendingTile({required this.req});
  final CallRequest req;

  @override
  ConsumerState<_PendingTile> createState() => _PendingTileState();
}

class _PendingTileState extends ConsumerState<_PendingTile> {
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

  @override
  Widget build(BuildContext context) {
    final r = widget.req;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.15),
                  child: const Text('D', style: TextStyle(color: AppColors.guruPrimary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(TimeFormat.dateAndTime(r.scheduledFor),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Requested ${TimeFormat.relative(r.requestedAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.subtle)),
                    ],
                  ),
                ),
              ],
            ),
            if (r.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(r.note, style: const TextStyle(fontSize: 13)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Decline', onPressed: _busy ? null : _decline),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(label: 'Approve', loading: _busy, onPressed: _approve),
                ),
              ],
            ),
          ],
        ),
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
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Tell DK why you\'re skipping this slot'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}

class _ApprovedTile extends StatelessWidget {
  const _ApprovedTile({required this.req});
  final CallRequest req;

  @override
  Widget build(BuildContext context) {
    final joinable = req.isJoinable;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(Icons.event_available_rounded,
            color: joinable ? AppColors.success : AppColors.subtle),
        title: Text(TimeFormat.dateAndTime(req.scheduledFor),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(req.note.isEmpty ? 'No note' : req.note,
            style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
        trailing: joinable
            ? FilledButton.tonal(
                onPressed: () => context.go('/home/prejoin/${req.id}'),
                child: const Text('Join'),
              )
            : null,
      ),
    );
  }
}
