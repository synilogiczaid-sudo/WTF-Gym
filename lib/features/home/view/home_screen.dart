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
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Coach dashboard', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 2),
                  Text(
                    "Today's overview",
                    style: TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            RoleBadge(role: 'Trainer', name: 'Aarav'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TrainerHomeBanners(),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.05,
                children: [
                  _Tile(
                    icon: Icons.group_outlined,
                    title: 'Members',
                    subtitle: 'Your roster',
                    onTap: () => context.go('/home/members'),
                  ),
                  _Tile(
                    icon: Icons.forum_outlined,
                    title: 'Chats',
                    subtitle: 'Recent conversations',
                    onTap: () => context.go('/home/chats'),
                  ),
                  _Tile(
                    icon: Icons.pending_actions_outlined,
                    title: 'Requests',
                    subtitle: 'Approve / decline',
                    onTap: () => context.go('/home/requests'),
                  ),
                  _Tile(
                    icon: Icons.history_rounded,
                    title: 'Sessions',
                    subtitle: 'Past calls',
                    onTap: () => context.go('/home/sessions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: c, size: 22),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
            ],
          ),
        ),
      ),
    );
  }
}
