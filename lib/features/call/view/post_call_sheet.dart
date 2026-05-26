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
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
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
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.note_alt_rounded, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Wrap up this session',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    const Text(
                      'Add a quick note for next time and mark complete when done.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.subtle, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
              Expanded(
                child: SecondaryButton(
                  label: 'Save',
                  icon: Icons.bookmark_outline_rounded,
                  onPressed: _busy ? null : () => _save(complete: false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Mark complete',
                  icon: Icons.check_rounded,
                  loading: _busy,
                  onPressed: () => _save(complete: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
