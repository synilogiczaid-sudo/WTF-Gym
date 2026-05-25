import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class TrainerPostCallSheet extends ConsumerStatefulWidget {
  const TrainerPostCallSheet({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<TrainerPostCallSheet> createState() => _TrainerPostCallSheetState();
}

class _TrainerPostCallSheetState extends ConsumerState<TrainerPostCallSheet> {
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save({required bool complete}) async {
    setState(() => _busy = true);
    await ref.read(logServiceProvider).patchSession(
          widget.sessionId,
          trainerNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          completed: complete ? true : null,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(complete
            ? 'Session saved and marked complete.'
            : 'Session saved to your logs.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wrap up this session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add a quick note for next time and mark complete when done.',
            style: TextStyle(fontSize: 13, color: AppColors.subtle),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Trainer notes',
              hintText: 'Focus areas, plan for next call, anything important…',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Save', onPressed: _busy ? null : () => _save(complete: false))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: PrimaryButton(label: 'Mark complete', loading: _busy, onPressed: () => _save(complete: true))),
            ],
          ),
        ],
      ),
    );
  }
}
