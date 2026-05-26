import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/chat_viewmodel.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync = ScreenSync(
        label: 'chat-list',
        tick: () async {
          final dir = ref.read(userDirectoryProvider);
          await dir.refresh();
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
    final threads = ref.watch(chatThreadsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Chats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/home/members'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New chat'),
        elevation: 2,
      ),
      body: SafeArea(
        child: threads.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: 6,
            itemBuilder: (_, __) => const SkeletonListTile(),
          ),
          error: (_, __) => const FriendlyError(title: "Couldn't load chats"),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.forum_outlined,
                title: 'No conversations yet',
                subtitle: 'Tap "New chat" to start chatting with a member.',
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.read(userDirectoryProvider).refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  100,
                ),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _ThreadCard(thread: list[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread});
  final ChatThread thread;

  bool get _isPlaceholder => thread.last.senderId.isEmpty;

  @override
  Widget build(BuildContext context) {
    final initial = thread.peerName.isNotEmpty
        ? thread.peerName.characters.first.toUpperCase()
        : '?';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: () => context.go('/home/chats/${thread.peerId}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.guruPrimary,
                      Color(0xFF4F8DEB),
                    ],
                  ),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.peerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: thread.unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.ink,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!_isPlaceholder)
                          Text(
                            TimeFormat.relative(thread.last.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: thread.unread > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : AppColors.subtle,
                              fontWeight: thread.unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.last.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isPlaceholder
                                  ? AppColors.muted
                                  : thread.unread > 0
                                      ? AppColors.ink
                                      : AppColors.subtle,
                              fontSize: 13,
                              fontStyle: _isPlaceholder
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (thread.unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${thread.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
