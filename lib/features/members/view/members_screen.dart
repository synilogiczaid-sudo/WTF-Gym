import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/members_viewmodel.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(userDirectoryProvider).refresh(),
          child: members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                FriendlyError(
                  title: "Couldn't load members",
                  onRetry: () => ref.invalidate(membersProvider),
                ),
              ],
            ),
            data: (list) {
              if (list.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    EmptyState(
                      icon: Icons.group_outlined,
                      title: 'No members yet',
                      subtitle:
                          'New members will show up here as they join.\nPull down to refresh.',
                    ),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final m = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.15),
                      child: Text(
                        m.name.characters.first.toUpperCase(),
                        style: const TextStyle(color: AppColors.guruPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
                    onTap: () => context.go('/home/chats/${m.id}'),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
