import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../../widgets/trainer_home_banners.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    // Poll the trainer roster + requests from the dashboard so badges
    // and chat-list counts stay fresh without opening every screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync = ScreenSync(
        label: 'trainer-home',
        tick: () async {
          final dir = ref.read(userDirectoryProvider);
          await dir.refresh();
          await ref.read(callServiceProvider).refresh();
          await ref
              .read(chatServiceProvider)
              .refreshChatsWith(dir.members.map((m) => m.id));
        },
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
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final dir = ref.read(userDirectoryProvider);
            await dir.refresh();
            await ref.read(callServiceProvider).refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _CoachHeader(name: user.name),
              const SizedBox(height: AppSpacing.md),
              const TrainerHomeBanners(),
              const _SectionLabel('Today\'s tools'),
              const SizedBox(height: AppSpacing.sm),
              const _DashboardGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.name});
  final String name;

  String get _timeOfDayLabel {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'C';
    return GestureDetector(
      onLongPress: () => _openDevPanel(context),
      child: Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md + 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
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
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeOfDayLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Coach $name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Trainer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _CoachStats(),
        ],
      ),
      ),
    );
  }

  void _openDevPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.settings_input_antenna_rounded,
                      color: AppColors.warning, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Dev · Server settings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Point both apps at your laptop\'s LAN IP. Saved across restarts.',
              style: TextStyle(fontSize: 12, color: AppColors.subtle, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            const ApiHostEditor(),
          ],
        ),
      ),
    );
  }
}

class _CoachStats extends ConsumerWidget {
  const _CoachStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final members = ref.watch(_memberCountProvider).valueOrNull ?? 0;
    final pending = ref.watch(_pendingCountProvider).valueOrNull ?? 0;
    final today = ref.watch(_todayCountProvider).valueOrNull ?? 0;
    if (user == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.group_rounded,
            label: 'Members',
            value: '$members',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            icon: Icons.event_available_rounded,
            label: 'Today',
            value: '$today',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            icon: Icons.notifications_active_rounded,
            label: 'Pending',
            value: '$pending',
            highlight: pending > 0,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.subtle,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _DashboardGrid extends ConsumerWidget {
  const _DashboardGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final pending = ref.watch(_pendingCountProvider).valueOrNull ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.sm + 2;
        final width = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _DashTile(
                icon: Icons.group_rounded,
                title: 'Members',
                subtitle: 'Your roster',
                accent: primary,
                onTap: () => context.go('/home/members'),
              ),
            ),
            SizedBox(
              width: width,
              child: _DashTile(
                icon: Icons.forum_rounded,
                title: 'Chats',
                subtitle: 'Recent conversations',
                accent: AppColors.guruPrimary,
                onTap: () => context.go('/home/chats'),
              ),
            ),
            SizedBox(
              width: width,
              child: _DashTile(
                icon: Icons.pending_actions_rounded,
                title: 'Requests',
                subtitle: 'Approve / decline',
                accent: AppColors.warning,
                badge: pending > 0 ? '$pending' : null,
                onTap: () => context.go('/home/requests'),
              ),
            ),
            SizedBox(
              width: width,
              child: _DashTile(
                icon: Icons.history_rounded,
                title: 'Sessions',
                subtitle: 'Past calls',
                accent: AppColors.success,
                onTap: () => context.go('/home/sessions'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashTile extends StatelessWidget {
  const _DashTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.14),
                          accent.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.16)),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtle,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lightweight derived providers used only by the dashboard hero. They reuse
// the same underlying services — no new state or polling — so they can't
// affect business logic.
// ---------------------------------------------------------------------------

final _memberCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(userDirectoryProvider)
      .watchAll()
      .map((all) => all.where((u) => u.role == UserRole.member).length);
});

final _pendingCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  return ref.watch(callServiceProvider).watchAll().map((all) => all
      .where((r) => r.trainerId == user.id && r.status == CallRequestStatus.pending)
      .length);
});

final _todayCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  return ref.watch(callServiceProvider).watchAll().map((all) {
    final now = DateTime.now();
    return all.where((r) {
      if (r.trainerId != user.id) return false;
      if (r.status != CallRequestStatus.approved) return false;
      final d = r.scheduledFor;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  });
});
