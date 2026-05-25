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
      appBar: AppBar(
        title: const Text('Chats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/home/members'),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: threads.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const FriendlyError(title: "Couldn't load chats"),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.forum_outlined,
                title: 'No conversations yet',
                subtitle: 'Tap + to start chatting with a member.',
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.read(userDirectoryProvider).refresh(),
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) => _ThreadTile(thread: list[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});
  final ChatThread thread;

  bool get _isPlaceholder => thread.last.senderId.isEmpty;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.15),
        child: Text(
          thread.peerName.characters.first.toUpperCase(),
          style: const TextStyle(color: AppColors.guruPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(thread.peerName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        thread.last.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.subtle, fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isPlaceholder)
            Text(TimeFormat.relative(thread.last.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.subtle)),
          if (thread.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text('${thread.unread}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      onTap: () => context.go('/home/chats/${thread.peerId}'),
    );
  }
}
